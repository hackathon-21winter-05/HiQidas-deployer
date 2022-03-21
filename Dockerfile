FROM node:16.14.2-alpine AS front-builder
WORKDIR /build
RUN apk add git

RUN git clone https://github.com/hackathon-21winter-05/HiQidas_UI.git
WORKDIR /build/HiQidas_UI
RUN npm ci --unsafe-perm
RUN npm run build

FROM logica0419/protoc-go:1.17.7 AS back-builder
WORKDIR /build

RUN git clone https://github.com/hackathon-21winter-05/HiQidas.git
WORKDIR /build/HiQidas
RUN make protobuf-go
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /HiQidas -ldflags '-s -w'

FROM caddy:2.4.6-alpine AS runner
RUN apk update && apk upgrade && apk add bash
EXPOSE 80

COPY --from=front-builder /build/HiQidas_UI/dist /usr/share/caddy
COPY --from=back-builder /HiQidas /
COPY ./Caddyfile /etc/caddy/Caddyfile

HEALTHCHECK CMD curl localhost:80/api/ping || exit 1
ENTRYPOINT caddy start --config /etc/caddy/Caddyfile --adapter caddyfile && /HiQidas
