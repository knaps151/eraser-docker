FROM golang:1.24-alpine AS builder

WORKDIR /src

RUN apk add --no-cache ca-certificates tzdata

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/eraser ./cmd/eraser

FROM alpine:3.22

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

COPY --from=builder /out/eraser /usr/local/bin/eraser
COPY data ./data

RUN addgroup -S eraser && adduser -S -G eraser eraser \
    && mkdir -p /home/eraser/.eraser \
    && chown -R eraser:eraser /home/eraser /app

USER eraser

ENV HOME=/home/eraser

VOLUME ["/home/eraser/.eraser"]

EXPOSE 8080

ENTRYPOINT ["eraser"]
CMD ["serve", "--port", "8080"]
