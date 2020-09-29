FROM gliderlabs/alpine:3.4

RUN \
  apk-install \
    curl \
    openssh-client \
    python \
    py-boto \
    py-dateutil \
    py-httplib2 \
    py-jinja2 \
    py-paramiko \
    py-pip \
    py-setuptools \
    py-yaml \
    tar && \
  pip install --upgrade pip python-keyczar && \
  rm -rf /var/cache/apk/*

RUN mkdir /etc/ansible/ /ansible
RUN mkdir -p /ansible/playbooks/tmp
RUN mkdir -p /.ansible/tmp
RUN chgrp -R 0 /.ansible/tmp && chmod -R g=u /.ansible/tmp

RUN addgroup -S ansible && adduser -S ansible -G ansible -h /ansible/playbooks

RUN echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts

RUN echo "[default]" > /etc/ansible/ansible.cfg
RUN echo "local_tmp = /tmp/.ansible/tmp" >> /etc/ansible/ansible.cfg
RUN echo "remote_tmp = /tmp/.ansible/tmp" >> /etc/ansible/ansible.cfg

RUN \
  curl -fsSL https://releases.ansible.com/ansible/ansible-2.2.2.0.tar.gz -o ansible.tar.gz && \
  tar -xzf ansible.tar.gz -C ansible --strip-components 1 && \
  rm -fr ansible.tar.gz /ansible/docs /ansible/examples /ansible/packaging

RUN chown -R ansible:ansible /ansible/playbooks
RUN chgrp -R 0 /ansible/playbooks && chmod -R g=u /ansible/playbooks

USER ansible
WORKDIR /ansible/playbooks
COPY . /ansible/playbooks
RUN mkdir -p /tmp/.ansible/tmp

ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING false
ENV ANSIBLE_RETRY_FILES_ENABLED false
ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
ENV ANSIBLE_SSH_PIPELINING True
ENV PATH /ansible/bin:$PATH
ENV PYTHONPATH /ansible/lib
ENV DEFAULT_LOCAL_TMP /tmp
ENV ANSIBLE_CONFIG /etc/ansible/ansible.cfg

ENTRYPOINT ["ansible-playbook","configure.yml"]
CMD ["-i","dev.yml"]

