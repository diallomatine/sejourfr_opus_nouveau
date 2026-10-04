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
import java.nio.charset.StandardCharsets;

/**
 * Octets d'images REELLES pour les tests (PNG/JPEG encodes par ImageIO), et
 * fichiers WEBP construits bloc par bloc (le JDK ne sait pas encoder le WEBP) —
 * suffisants pour la signature, les dimensions et les donnees d'alpha.
 */
public final class ImagesDeTest {

    private ImagesDeTest() {}

    /** PNG opaque, fond blanc et un trait noir. */
    public static byte[] png(int largeur, int hauteur) {
        BufferedImage img = new BufferedImage(largeur, hauteur, BufferedImage.TYPE_INT_RGB);
        dessiner(img);
        return encoder(img, "png");
    }

    /** PNG 1 bit (fichier et memoire minimes) : pour les grandes dimensions. */
    public static byte[] pngNoirEtBlanc(int largeur, int hauteur) {
        return encoder(new BufferedImage(largeur, hauteur, BufferedImage.TYPE_BYTE_BINARY), "png");
    }

    /** PNG RGBA : entierement opaque si {@code transparente} est faux. */
    public static byte[] pngRgba(int largeur, int hauteur, boolean transparente) {
        BufferedImage img = new BufferedImage(largeur, hauteur, BufferedImage.TYPE_INT_ARGB);
        dessiner(img);
        if (transparente) img.setRGB(0, 0, 0x00FFFFFF);
        return encoder(img, "png");
    }

    /** PNG RGBA opaque sauf un pixel d'alpha {@code alpha} (0-254 : transparent ; 255 : opaque). */
    public static byte[] pngRgbaUnPixel(int largeur, int hauteur, int alpha) {
        BufferedImage img = new BufferedImage(largeur, hauteur, BufferedImage.TYPE_INT_ARGB);
        dessiner(img);
        img.setRGB(largeur / 2, hauteur / 2, alpha << 24 | 0xFFFFFF);
        return encoder(img, "png");
    }

    /** PNG en palette dont une entree est transparente ({@code tRNS}), utilisee par un pixel. */
    public static byte[] pngPaletteAvecTrns(int largeur, int hauteur) {
        java.awt.image.IndexColorModel palette = new java.awt.image.IndexColorModel(8, 2,
                new byte[] {(byte) 0xFF, 0}, new byte[] {(byte) 0xFF, 0}, new byte[] {(byte) 0xFF, 0},
                new byte[] {(byte) 0xFF, 0});
        BufferedImage img = new BufferedImage(largeur, hauteur, BufferedImage.TYPE_BYTE_INDEXED, palette);
        img.getRaster().setSample(1, 1, 0, 1);
        return encoder(img, "png");
    }

    public static byte[] jpeg(int largeur, int hauteur) {
        BufferedImage img = new BufferedImage(largeur, hauteur, BufferedImage.TYPE_INT_RGB);
        dessiner(img);
        return encoder(img, "jpg");
    }

    /**
     * WEBP etendu (VP8X) suivi d'une trame VP8. {@code alpha} : drapeau alpha
     * pose ET bloc ALPH compresse (ce qu'ecrit libwebp pour une image qui a
     * reellement des pixels transparents).
     */
    public static byte[] webpVp8x(int largeur, int hauteur, boolean alpha) {
        return alpha
                ? webpEtendu(largeur, hauteur, true, bloc("ALPH", new byte[] {0x01, 0x10, 0x20, 0x30}), trameVp8(largeur, hauteur))
                : webpEtendu(largeur, hauteur, false, trameVp8(largeur, hauteur));
    }

    /** WEBP etendu dont le drapeau alpha est pose mais SANS bloc ALPH (aucune donnee d'alpha). */
    public static byte[] webpVp8xDrapeauSansAlph(int largeur, int hauteur) {
        return webpEtendu(largeur, hauteur, true, trameVp8(largeur, hauteur));
    }

    /** WEBP etendu avec un bloc ALPH brut non filtre : {@code plan} = un octet d'alpha par pixel. */
    public static byte[] webpVp8xAlphBrut(int largeur, int hauteur, byte[] plan) {
        byte[] alph = new byte[plan.length + 1];
        System.arraycopy(plan, 0, alph, 1, plan.length);
        return webpEtendu(largeur, hauteur, true, bloc("ALPH", alph), trameVp8(largeur, hauteur));
    }

    /** WEBP etendu dont l'image est un bloc VP8L, indice alpha au choix. */
    public static byte[] webpVp8xVp8l(int largeur, int hauteur, boolean alpha) {
        return webpEtendu(largeur, hauteur, alpha, bloc("VP8L", enteteVp8l(largeur, hauteur, alpha)));
    }

    /** En-tete WEBP avec un bloc VP8L (sans perte), 14 bits par dimension. */
    public static byte[] webpVp8l(int largeur, int hauteur, boolean alpha) {
        return riff(bloc("VP8L", enteteVp8l(largeur, hauteur, alpha)));
    }

    /** En-tete WEBP avec un bloc VP8 (avec perte), trame cle. */
    public static byte[] webpVp8(int largeur, int hauteur) {
        return riff(trameVp8(largeur, hauteur));
    }

    private static byte[] webpEtendu(int largeur, int hauteur, boolean drapeauAlpha, byte[]... blocs) {
        ByteBuffer vp8x = ByteBuffer.allocate(10).order(ByteOrder.LITTLE_ENDIAN);
        vp8x.put((byte) (drapeauAlpha ? 0x10 : 0x00)).put(new byte[3]);
        le24(vp8x, largeur - 1);
        le24(vp8x, hauteur - 1);
        byte[][] tous = new byte[blocs.length + 1][];
        tous[0] = bloc("VP8X", vp8x.array());
        System.arraycopy(blocs, 0, tous, 1, blocs.length);
        return riff(tous);
    }

    private static byte[] enteteVp8l(int largeur, int hauteur, boolean alpha) {
        ByteBuffer b = ByteBuffer.allocate(10).order(ByteOrder.LITTLE_ENDIAN);
        b.put((byte) 0x2F);
        long bits = (largeur - 1L) | (hauteur - 1L) << 14 | (alpha ? 1L : 0L) << 28;
        b.putInt((int) bits);
        return b.array();
    }

    private static byte[] trameVp8(int largeur, int hauteur) {
        ByteBuffer b = ByteBuffer.allocate(10).order(ByteOrder.LITTLE_ENDIAN);
        b.put(new byte[3]);
        b.put((byte) 0x9D).put((byte) 0x01).put((byte) 0x2A);
        b.putShort((short) largeur).putShort((short) hauteur);
        return bloc("VP8 ", b.array());
    }

    /** Un bloc RIFF : FourCC, taille, donnees, octet de bourrage si la taille est impaire. */
    private static byte[] bloc(String fourcc, byte[] donnees) {
        int bourrage = donnees.length & 1;
        ByteBuffer b = ByteBuffer.allocate(8 + donnees.length + bourrage).order(ByteOrder.LITTLE_ENDIAN);
        b.put(fourcc.getBytes(StandardCharsets.US_ASCII)).putInt(donnees.length).put(donnees);
        return b.array();
    }

    private static byte[] riff(byte[]... blocs) {
        int taille = 0;
        for (byte[] bl : blocs) taille += bl.length;
        ByteBuffer b = ByteBuffer.allocate(12 + taille).order(ByteOrder.LITTLE_ENDIAN);
        b.put("RIFF".getBytes(StandardCharsets.US_ASCII)).putInt(4 + taille).put("WEBP".getBytes(StandardCharsets.US_ASCII));
        for (byte[] bl : blocs) b.put(bl);
        return b.array();
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
