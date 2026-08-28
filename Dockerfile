# Nothing but curl and a loop. The work happens in Vercel; this only makes
# sure something asks for it, continuously.
FROM alpine:3.20

RUN apk add --no-cache curl ca-certificates

COPY tick.sh /tick.sh
RUN chmod +x /tick.sh

ENTRYPOINT ["/bin/sh", "/tick.sh"]
