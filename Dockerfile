FROM dart:stable AS build

WORKDIR /src/gengen

COPY pubspec.yaml pubspec.lock /src/gengen/
RUN dart pub get

COPY . /src/gengen

RUN dart run build_runner build

RUN dart compile exe bin/main.dart  -o gengen

FROM alpine:3.19.0

COPY --from=build /src/gengen/gengen /app/gengen

RUN apk update && \
    apk add --no-cache ca-certificates libc6-compat libstdc++

VOLUME /site
WORKDIR /site

EXPOSE 1313

ENTRYPOINT ["/app/gengen"]
CMD ["--help"]