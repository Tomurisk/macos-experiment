#!/bin/bash

# ============================
# PeaZip — Archive Formats
# ============================

PEAZIP_BID="com.peazip.peazip"

PEAZIP_UTIS=(
  "public.zip-archive"
  "public.tar-archive"
  "com.sun.java-archive"
  "public.bzip2-archive"
  "com.allume.stuffit-archive"
  "org.gnu.gnu-zip-archive"
  "org.gnu.gnu-tar-archive"
  "com.pkware.zip-archive"
)

echo ""
echo "=== Setting archive handlers to PeaZip ==="
for uti in "${PEAZIP_UTIS[@]}"; do
  echo "Setting default handler for $uti..."
  utiluti type set "$uti" "$PEAZIP_BID"
  sleep 0.5
done


# ============================
# FlowVision — Image Formats Only
# ============================

FLOWVISION_BID="netdcy.FlowVision"

FLOWVISION_IMAGE_UTIS=(
  "public.jpeg"
  "public.png"
  "com.microsoft.bmp"
  "public.tiff"
  "public.heif"
  "org.webmproject.webp"
  "public.image"
  "public.heic"
  "public.jpeg-2000"
  "netdcy.flowvision.jfif"
)

echo ""
echo "=== Setting image handlers to FlowVision ==="
for uti in "${FLOWVISION_IMAGE_UTIS[@]}"; do
  echo "Setting default handler for $uti..."
  utiluti type set "$uti" "$FLOWVISION_BID"
  sleep 0.5
done


# ============================
# IINA — Video, Audio, Playlists
# ============================

IINA_BID="com.colliderli.iina"

IINA_UTIS=(
  # Video
  "public.movie"
  "public.video"
  "public.mpeg"
  "public.mpeg-4"
  "com.apple.quicktime-movie"
  "com.apple.m4v-video"
  "public.3gpp"
  "public.3gpp2"
  "public.mpeg-2-video"
  "public.mpeg-2-transport-stream"

  # Audio
  "public.audio"
  "public.mp3"
  "public.aac-audio"
  "public.mpeg-4-audio"
  "com.microsoft.waveform-audio"
  "org.xiph.flac"
  "public.ulaw-audio"

  # Playlists
  "public.m3u-playlist"

  # Generic containers
  "public.data"
  "public.item"
)

echo ""
echo "=== Setting media handlers to IINA ==="
for uti in "${IINA_UTIS[@]}"; do
  echo "Setting default handler for $uti..."
  utiluti type set "$uti" "$IINA_BID"
  sleep 0.5
done

echo ""
echo "Finished processing all file associations."
