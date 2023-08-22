FROM elixir:1.15-alpine AS build

ENV MIX_ENV=prod

WORKDIR /app

# get deps first so we have a cache
ADD mix.exs mix.lock /app/
RUN \
	cd /app && \
	mix local.hex --force && \
	mix local.rebar --force && \
	mix deps.get

# then make a release build
ADD . /app/

RUN \
	mix compile && \
	mix release

FROM elixir:1.15-alpine
RUN apk add --update nodejs npm

COPY --from=build /app/js_image/package.json /js_image/package.json
COPY --from=build /app/js_image/package-lock.json /js_image/package-lock.json
# install js deps
WORKDIR /js_image
RUN npm ci
WORKDIR /

COPY --from=build /app/js_image /js_image
COPY --from=build /app/_build/prod/rel/dafarmz_bot /opt/dafarmz_bot

EXPOSE 4000

CMD [ "/opt/dafarmz_bot/bin/dafarmz_bot", "start" ]
