# DaFarmz Bot

![Preview](https://raw.githubusercontent.com/ZaneH/dafarmz-website/main/img/plot.png)

## Run Locally

### Clone the project

```bash
git clone https://github.com/ZaneH/dafarmz-bot.git
cd dafarmz-bot
```

### Setup environment variables

You'll need to create an application in the Discord Developer Portal to
get a token for your bot. You'll also need to enable developer mode in
Discord to get your bot's user ID.

The permissions your bot needs includes:

- Read Messages
- Send Messages
- Manage Messages
- Read Message History
- Add Reactions (unused, but planned)

```
# .env
export DISCORD_USER_ID=<your bot's user ID>
export DISCORD_TOKEN=<your bot's token>
```

### Install dependencies

```bash
mix deps.get
```

### Install JS dependencies

```bash
cd js_image/
npm install
cd ..
```

### Create database

```bash
mix ecto.create
```

### Run migrations

Currently there is no seed data. You'll need to populate the database
manually with shop items, lifecycle images, etc.

```bash
mix ecto.migrate
```

### Run the bot

```bash
iex -S mix
```

## License

<a href="https://creativecommons.org/licenses/by-nc-nd/4.0/">
    <img height="50px" src="https://mirrors.creativecommons.org/presskit/buttons/88x31/png/by-nc-nd.png" />
</a>

### In English

You are free to:
- Share — copy and redistribute the material in any medium or format
    - The licensor cannot revoke these freedoms as long as you follow the license terms.

Under the following terms:
- Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
- NonCommercial — You may not use the material for commercial purposes.
- NoDerivatives — If you remix, transform, or build upon the material, you may not distribute the modified material.

## Assets

Game assets in the 1.0 version are from [Sprout Lands asset pack by Cup Nooble](https://cupnooble.itch.io/sprout-lands-asset-pack). Due to their license, I will not be redistributing these assets.

If you run this locally, you'll need the following files:

- `js_image/images/layer-1-v2.png` (For the base image, grid + grass)
- `js_image/images/layer-2-v2.png` (For the base image, border decoration)
- `js_image/images/*.png` (For the lifecycle images. These need to be added to the database manually for each `item` row.)