const jimp = require("jimp");

const GRID_SIZE = 32;
const PLOT_OFFSET = 29;

const generateBaseImage = async () => {
    const layer1 = await jimp.read("./js_image/images/layer-1-v2.png");
    const layer2 = await jimp.read("./js_image/images/layer-2-v2.png");

    return layer1.composite(layer2, 0, 0);
};

const placeObject = async (baseImage, objectPath, gridX, gridY) => {
    const object = await jimp.read("./js_image/images/" + objectPath);
    const w = object.bitmap.width;
    const h = object.bitmap.height;
    const x = gridX * GRID_SIZE + PLOT_OFFSET - w / 2;
    const y = gridY * GRID_SIZE + PLOT_OFFSET - h / 2;

    let additionalOffsets = { x: GRID_SIZE / 2, y: GRID_SIZE / 2 };
    if (h > GRID_SIZE) {
        additionalOffsets.y -= h / 4;
    }

    return baseImage.composite(
        object,
        x + additionalOffsets.x,
        y + additionalOffsets.y
    );
};

const generateImage = async (jsonInput) => {
    const json = JSON.parse(jsonInput);
    const { state, discord_user_id } = json || {};
    const sortedState = state.sort((a, b) => {
        return a.y - b.y;
    });

    const baseImage = await generateBaseImage();
    let finalImage = baseImage;
    for (let i = 0; i < sortedState.length; i++) {
        finalImage = await placeObject(
            finalImage,
            sortedState[i].image,
            sortedState[i].x,
            sortedState[i].y
        );
    }

    const path = `./js_image/output/${discord_user_id || "grass-128"}.png`;
    await finalImage.writeAsync(path);

    return path;
};

module.exports = async (jsonInput) => {
    return await generateImage(jsonInput);
};
