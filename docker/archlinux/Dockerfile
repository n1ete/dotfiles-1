FROM archlinux/base:latest
# Locales keyboard
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
 && locale-gen \
 && echo 'LANG="en_US.UTF-8"' > /etc/locale.conf
ENV LANG="en_US.UTF-8"
# Archlinux Deps
RUN pacman -Syu --noconfirm \
      sudo \
      binutils \
      util-linux \
      fakeroot \
      file \
      python \
      yajl \
      make \
      gcc \
      pkg-config \
      which \
      perl \
      automake \
      autoconf \
      gettext \
      patch \
      rsync \
      xorg-server-xephyr
ENV PATH="${PATH}:/usr/bin/core_perl"
# Project deps
RUN pacman -S --noconfirm \
      git \
      kakoune
# Fix tmp dir perms
RUN chmod 1777 /tmp
# Create test user
RUN useradd -m user \
 && chown -R user:user /home/user \
 && echo -e "user\nuser" | passwd user
RUN echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# gpg keys
RUN pacman-key --init && curl -s https://keys.openpgp.org/vks/v1/by-fingerprint/4AA5A5A3602162EF1459D24D3129FAE7E854EDEF | pacman-key -a - && \
    pacman-key --lsign-key "0x174377F0170A7594"

# install blackarch gpg keys
RUN curl -sL https://blackarch.org/strap.sh | bash

# pacman config
COPY docker/archlinux/pacman.conf /etc/pacman.conf

# User run
USER user
WORKDIR /home/user/.dotfiles
ENV LANG="de_DE.UTF-8"
COPY . .
CMD ["/bin/bash"]
