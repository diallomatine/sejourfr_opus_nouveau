package com.sejourfr.app.util;

import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ClientIpExtractorTest {

    private HttpServletRequest req(String xff, String realIp, String remoteAddr) {
        HttpServletRequest r = mock(HttpServletRequest.class);
        when(r.getHeader("X-Forwarded-For")).thenReturn(xff);
        when(r.getHeader("X-Real-IP")).thenReturn(realIp);
        when(r.getRemoteAddr()).thenReturn(remoteAddr);
        return r;
    }

    @Test
    void nullRequest_returnsNull() {
        assertThat(ClientIpExtractor.extract(null)).isNull();
    }

    @Test
    void forwardedFor_takesFirstIpAndTrims() {
        assertThat(ClientIpExtractor.extract(req(" 1.2.3.4 , 5.6.7.8 , 9.9.9.9", null, "10.0.0.1")))
                .isEqualTo("1.2.3.4");
    }

    @Test
    void forwardedFor_singleValue() {
        assertThat(ClientIpExtractor.extract(req("203.0.113.5", null, "10.0.0.1")))
                .isEqualTo("203.0.113.5");
    }

    @Test
    void blankForwardedFor_fallsBackToRealIp() {
        assertThat(ClientIpExtractor.extract(req("   ", "198.51.100.7", "10.0.0.1")))
                .isEqualTo("198.51.100.7");
    }

    @Test
    void unknownForwardedFor_fallsBackToRealIp() {
        assertThat(ClientIpExtractor.extract(req("unknown", "198.51.100.7", "10.0.0.1")))
                .isEqualTo("198.51.100.7");
    }

    @Test
    void noHeaders_fallsBackToRemoteAddr() {
        assertThat(ClientIpExtractor.extract(req(null, null, "10.0.0.1")))
                .isEqualTo("10.0.0.1");
    }

    @Test
    void unknownRemoteAddr_returnsNull() {
        assertThat(ClientIpExtractor.extract(req(null, null, "unknown"))).isNull();
    }

    @Test
    void allBlank_returnsNull() {
        assertThat(ClientIpExtractor.extract(req("", "", ""))).isNull();
    }
}
