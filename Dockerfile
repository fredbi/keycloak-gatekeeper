FROM golang:alpine as builder

RUN mkdir -p /stage/data /stage/etc/ssl/certs &&\
  apk add --no-cache musl-dev gcc ca-certificates mailcap upx tzdata zip openssh git &&\
  update-ca-certificates &&\
  cp /etc/ssl/certs/ca-certificates.crt /stage/etc/ssl/certs/ca-certificates.crt &&\
  cp /etc/mime.types /stage/etc/mime.types

WORKDIR /usr/share/zoneinfo
RUN zip -r -0 /stage/zoneinfo.zip .

#RUN go get -u github.com/golang/dep/cmd/dep
ADD . /go/src/github.com/fredbi/keycloak-gatekeeper

#WORKDIR /go/src/github.com/fredbi
#RUN git clone https://github.com/fredbi/keycloak-gatekeeper
WORKDIR /go/src/github.com/fredbi/keycloak-gatekeeper
#RUN dep ensure

RUN mkdir -p /stage/opt && mkdir -p /stage/opt/templates
RUn cp -a templates/ /stage/opt/templates

# Build go static binary
RUN go build -o /stage/opt/keycloak-gatekeeper --ldflags '-s -w -linkmode external -extldflags "-static"'

# Strip binary image
RUN upx /stage/opt/keycloak-gatekeeper


FROM scratch
LABEL Name=keycloak-gatekeeper \
      Release=https://github.com/fredbi/keycloak-gatekeeper \
      Url=https://github.com/fredbi/keycloak-gatekeeper \
      Help=https://github.com/fredbi/keycloak-gatekeeper/issues
COPY --from=builder /stage /
ENV ZONEINFO /zoneinfo.zip
ENTRYPOINT [ "/opt/keycloak-gatekeeper" ]
WORKDIR "/opt"
