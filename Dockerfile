FROM openeuler/openeuler:23.03 as BUILDER
RUN dnf update -y && \
    dnf install -y golang make git && \
    go env -w GOPROXY=https://goproxy.cn,direct

MAINTAINER zengchen1024<chenzeng765@gmail.com>

# build binary
WORKDIR /go/src/github.com/opensourceways/robot-gitee-software-package
COPY . .
RUN GO111MODULE=on CGO_ENABLED=0 go build -a -o robot-gitee-software-package .
RUN git clone https://github.com/git-lfs/git-lfs.git -b v3.4.0 && \
    cd git-lfs && \
    make

# copy binary config and utils
FROM openeuler/openeuler:22.03
RUN dnf -y update && \
    dnf in -y shadow git cpio && \
    groupadd -g 1000 robot-gitee-software-package && \
    useradd -u 1000 -g robot-gitee-software-package -s /bin/bash -m robot-gitee-software-package

USER robot-gitee-software-package

COPY --chown=robot-gitee-software-package --from=BUILDER /go/src/github.com/opensourceways/robot-gitee-software-package/robot-gitee-software-package /opt/app/robot-gitee-software-package
COPY --chown=robot-gitee-software-package softwarepkg/infrastructure/pullrequestimpl/create_branch.sh /opt/app/create_branch.sh
COPY --chown=robot-gitee-software-package softwarepkg/infrastructure/pullrequestimpl/clone_repo.sh /opt/app/clone_repo.sh
COPY --chown=robot-gitee-software-package softwarepkg/infrastructure/codeimpl/push_code.sh /opt/app/push_code.sh
COPY --chown=robot-gitee-software-package softwarepkg/infrastructure/template /opt/app/template
COPY --chown=root --chmod=755 --from=BUILDER /go/src/github.com/opensourceways/robot-gitee-software-package/git-lfs/bin/git-lfs /usr/local/bin/git-lfs
RUN chmod +x /opt/app/create_branch.sh /opt/app/clone_repo.sh /opt/app/push_code.sh

ENTRYPOINT ["/opt/app/robot-gitee-software-package"]
