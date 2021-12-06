FROM node:16.13.1-alpine AS front-builder
WORKDIR /build
RUN apk add git

RUN git clone https://github.com/hackathon-21winter-05/HiQidas_UI.git
WORKDIR /build/HiQidas_UI
RUN npm ci --unsafe-perm
RUN npm run build

FROM namely/protoc-all:1.14_0 AS protobuf-builder
WORKDIR /build
RUN apk add git make

RUN git clone https://github.com/hackathon-21winter-05/HiQidas.git
WORKDIR /build/HiQidas
RUN make protobuf-go

FROM golang:1.17.3-alpine AS back-builder
COPY --from=protobuf-builder /build /build

WORKDIR /build/HiQidas
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /HiQidas -ldflags '-s -w'

FROM caddy:2.4.6-alpine AS runner
RUN apk update && apk upgrade && apk add bash
EXPOSE 80

COPY --from=front-builder /build/HiQidas_UI/dist /usr/share/caddy
COPY --from=back-builder /HiQidas /
COPY ./Caddyfile /etc/caddy/Caddyfile

HEALTHCHECK CMD ./HiQidas healthcheck || exit 1
ENTRYPOINT caddy start --config /etc/caddy/Caddyfile --adapter caddyfile && /HiQidas
