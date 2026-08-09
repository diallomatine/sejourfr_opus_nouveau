package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** Configuration du diagnostic rapide, distincte de la notation TCF /20. */
@ConfigurationProperties(prefix = "sejourfr.diagnostic")
public class DiagnosticProperties {

    private String initialCode = "INITIAL_TCF";
    private Analysis analysis = new Analysis();

    public String getInitialCode() { return initialCode; }
    public void setInitialCode(String initialCode) { this.initialCode = initialCode; }
    public Analysis getAnalysis() { return analysis; }
    public void setAnalysis(Analysis analysis) { this.analysis = analysis; }

    public static class Analysis {
        private String rubricsVersion = "v1";
        private String toolSchemaVersion = "v1";
        private int maxTokens = 2200;
        private double temperature = 0;
        private int maxSessionRetries = 3;

        public String getRubricsVersion() { return rubricsVersion; }
        public void setRubricsVersion(String rubricsVersion) { this.rubricsVersion = rubricsVersion; }
        public String getToolSchemaVersion() { return toolSchemaVersion; }
        public void setToolSchemaVersion(String toolSchemaVersion) { this.toolSchemaVersion = toolSchemaVersion; }
        public int getMaxTokens() { return maxTokens; }
        public void setMaxTokens(int maxTokens) { this.maxTokens = maxTokens; }
        public double getTemperature() { return temperature; }
        public void setTemperature(double temperature) { this.temperature = temperature; }
        public int getMaxSessionRetries() { return maxSessionRetries; }
        public void setMaxSessionRetries(int maxSessionRetries) { this.maxSessionRetries = maxSessionRetries; }
    }
}
