package com.sejourfr.app.support;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * Octets d'images REELLES pour les tests (PNG/JPEG encodes par ImageIO), et
 * en-tetes WEBP construits a la main (le JDK ne sait pas encoder le WEBP) —
 * suffisants pour la signature, les dimensions et le drapeau alpha.
 */
public final class ImagesDeTest {

    private ImagesDeTest() {}

    /** PNG opaque, fond blanc et un trait noir. */
    public static byte[] png(int largeur, int hauteur) {
        BufferedImage img = new BufferedImage(largeur, hauteur, BufferedImage.TYPE_INT_RGB);
        dessiner(img);
        return encoder(img, "png");
    }

    /** PNG RGBA : entierement opaque si {@code transparente} est faux. */
    public static byte[] pngRgba(int largeur, int hauteur, boolean transparente) {
        BufferedImage img = new BufferedImage(largeur, hauteur, BufferedImage.TYPE_INT_ARGB);
        dessiner(img);
        if (transparente) img.setRGB(0, 0, 0x00FFFFFF);
        return encoder(img, "png");
    }

    public static byte[] jpeg(int largeur, int hauteur) {
        BufferedImage img = new BufferedImage(largeur, hauteur, BufferedImage.TYPE_INT_RGB);
        dessiner(img);
        return encoder(img, "jpg");
    }

    /** En-tete WEBP avec un bloc VP8X (format etendu), drapeau alpha au choix. */
    public static byte[] webpVp8x(int largeur, int hauteur, boolean alpha) {
        ByteBuffer b = riff("VP8X", 10);
        b.put((byte) (alpha ? 0x10 : 0x00)).put(new byte[3]);
        le24(b, largeur - 1);
        le24(b, hauteur - 1);
        return b.array();
    }

    /** En-tete WEBP avec un bloc VP8L (sans perte), 14 bits par dimension. */
    public static byte[] webpVp8l(int largeur, int hauteur, boolean alpha) {
        ByteBuffer b = riff("VP8L", 10);
        b.put((byte) 0x2F);
        long bits = (largeur - 1L) | (hauteur - 1L) << 14 | (alpha ? 1L : 0L) << 28;
        b.putInt((int) bits);
        b.put(new byte[5]);
        return b.array();
    }

    /** En-tete WEBP avec un bloc VP8 (avec perte), trame cle. */
    public static byte[] webpVp8(int largeur, int hauteur) {
        ByteBuffer b = riff("VP8 ", 10);
        b.put(new byte[3]);
        b.put((byte) 0x9D).put((byte) 0x01).put((byte) 0x2A);
        b.putShort((short) largeur).putShort((short) hauteur);
        return b.array();
    }

    private static ByteBuffer riff(String bloc, int tailleBloc) {
        ByteBuffer b = ByteBuffer.allocate(20 + tailleBloc).order(ByteOrder.LITTLE_ENDIAN);
        b.put("RIFF".getBytes()).putInt(12 + tailleBloc).put("WEBP".getBytes());
        b.put(bloc.getBytes()).putInt(tailleBloc);
        return b;
    }

    private static void le24(ByteBuffer b, int v) {
        b.put((byte) v).put((byte) (v >> 8)).put((byte) (v >> 16));
    }

    private static void dessiner(BufferedImage img) {
        Graphics2D g = img.createGraphics();
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, img.getWidth(), img.getHeight());
        g.setColor(Color.BLACK);
        g.drawLine(0, 0, img.getWidth() - 1, img.getHeight() - 1);
        g.dispose();
    }

    private static byte[] encoder(BufferedImage img, String format) {
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            ImageIO.write(img, format, out);
            return out.toByteArray();
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
