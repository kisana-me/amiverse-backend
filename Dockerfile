FROM ruby:3.4.7
RUN apt-get update && apt-get install -y build-essential imagemagick libvips ffmpeg
COPY ./config/imagemagick/policy.xml /etc/ImageMagick-6/policy.xml
RUN gem i -v 8.1.1 rails
