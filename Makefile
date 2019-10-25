DOCKER_USER:=ccromer
DOCKER_ORGANIZATION=artixlinux
DOCKER_IMAGE_BASE:=base
DOCKER_IMAGE_OPENRC:=openrc
DOCKER_IMAGE_RUNIT:=runit

BUILDDIR=build
PWD=$(shell pwd)

hooks:
	mkdir -p alpm-hooks/usr/share/libalpm/hooks
	find /usr/share/libalpm/hooks -exec ln -s /dev/null $(PWD)/alpm-hooks{} \;

rootfs: hooks
	mkdir -vp $(BUILDDIR)/var/lib/pacman/
	fakechroot -- fakeroot -- pacman -Sy -r $(BUILDDIR) \
		--noconfirm --dbpath $(PWD)/$(BUILDDIR)/var/lib/pacman \
		--config pacman.conf \
		--noscriptlet \
		--hookdir $(PWD)/alpm-hooks/usr/share/libalpm/hooks/ $(shell cat packages)
	cp --recursive --preserve=timestamps --backup --suffix=.pacnew rootfs/* $(BUILDDIR)/
	
	sed -i -e 's/^root::/root:!:/' "$(BUILDDIR)/etc/shadow"

	fakeroot -- tar --numeric-owner --xattrs --acls --exclude-from=exclude -C $(BUILDDIR) -c . -f dockerfile/base/artixlinux.tar
	rm -rf $(BUILDDIR) alpm-hooks

docker-image: rootfs
	docker build -t $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE_BASE) ./dockerfile/base
	docker build -t $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE_OPENRC) ./dockerfile/openrc
	docker build -t $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE_RUNIT) ./dockerfile/runit

docker-image-test: docker-image
	# FIXME: /etc/mtab is hidden by docker so the stricter -Qkk fails
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE_BASE) sh -c "/usr/bin/pacman -Sy && /usr/bin/pacman -Qqk"
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE_BASE) sh -c "/usr/bin/pacman -Syu --noconfirm docker && docker -v"
	# Ensure that the image does not include a private key
	! docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE_BASE) pacman-key --lsign-key cromer@artixlinux.org
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE_BASE) sh -c "/usr/bin/id -u http"
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE_BASE) sh -c "/usr/bin/pacman -Syu --noconfirm grep && locale | grep -q UTF-8"

docker-push:
	docker login -u $(DOCKER_USER)
	docker push $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE_BASE)
	docker push $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE_OPENRC)
	docker push $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE_RUNIT)

.PHONY: hooks rootfs docker-image docker-image-test docker-push
