.PHONY: build build-arch run ssh

SSH_DIR := $(CURDIR)/.local/ssh

build:
	docker build --tag devbox-debian:local images/debian

build-arch:
	docker build --tag devbox-arch:local images/arch

run: build
	install -d -m 0700 "$(SSH_DIR)"
	test -f "$(SSH_DIR)/id_ed25519" || ssh-keygen -q -t ed25519 -N "" -f "$(SSH_DIR)/id_ed25519"
	rm -f "$(SSH_DIR)/known_hosts"
	docker run --rm --name devbox-local \
		--publish 127.0.0.1:2222:22 \
		--mount "type=bind,source=$(SSH_DIR)/id_ed25519.pub,target=/tmp/devbox.pub,readonly" \
		devbox-debian:local sh -ec '\
			apt-get update; \
			DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openssh-server; \
			useradd --create-home --shell /bin/bash devbox; \
			install -d -m 0700 -o devbox -g devbox /home/devbox/.ssh; \
			install -m 0600 -o devbox -g devbox /tmp/devbox.pub /home/devbox/.ssh/authorized_keys; \
			install -d -m 0755 /run/sshd; \
			exec /usr/sbin/sshd -D -e \
				-o PasswordAuthentication=no \
				-o KbdInteractiveAuthentication=no \
				-o PermitRootLogin=no \
				-o AllowUsers=devbox'

ssh:
	ssh -F /dev/null -i "$(SSH_DIR)/id_ed25519" \
		-o IdentitiesOnly=yes \
		-o IdentityAgent=none \
		-o UserKnownHostsFile="$(SSH_DIR)/known_hosts" \
		-o StrictHostKeyChecking=accept-new \
		-p 2222 devbox@127.0.0.1
