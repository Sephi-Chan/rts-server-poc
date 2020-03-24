// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css";
import { Socket } from "phoenix";
import * as PIXI from "pixi.js";

let knight, socket, channel;
const sprites = {};
const app = new PIXI.Application({ width: 400, height: 400});
window.app = app;
window.sprites = sprites;
window.knight = knight;
window.PIXI = PIXI;

function initialize(name) {
  socket = new Socket("/socket", { params: { name } });
  channel = socket.channel("rooms:any");
  channel.on("player_joined", playerJoined);
  channel.on("player_left", playerLeft);
  channel.on("unit_stepped", unitStepped);
  channel.join().receive("ok", didJoin);

  const board = document.getElementById("board");
  board.appendChild(app.view);
  board.addEventListener('click', boardClicked);

  PIXI.Loader.shared
    .add("Corwin", "/images/knight-1.png")
    .add("Mandor", "/images/knight-2.png")
    .add("default", "/images/knight-2.png")
    .load(assetsLoaded);
}


window.onload = function() {
  const url = new URL(location.href);
  const name = url.searchParams.get("name");
  name && initialize(name);
}


function didJoin(units) {
  Object.entries(units).map(function([unitId, unit]) {
    const sprite = createUnitSprite(unit);
    app.stage.addChild(sprite);
    sprites[unit.id] = sprite;
  });
}


function playerJoined(unit) {
  const sprite = createUnitSprite(unit);
  app.stage.addChild(sprite);
  sprites[unit.id] = sprite;
}


function playerLeft({ unit_id: unitId }) {
  app.stage.removeChild(sprites[unitId]);
  delete sprites[unitId];
}


function unitStepped(unit) {
  const [x, y] = unit.location;
  sprites[unit.id].position.set(x, y);
}


function assetsLoaded() {
  socket.connect();
}


function createUnitSprite(unit) {
  const [x, y] = unit.location;
  const resource = PIXI.Loader.shared.resources[unit.id] || PIXI.Loader.shared.resources.default;
  const sprite = new PIXI.Sprite(resource.texture);
  sprite.width = 50;
  sprite.height = 50;
  sprite.anchor.set(0.5);
  sprite.position.set(x, y);
  return sprite;
}


function boardClicked(event) {
  var rectangle = event.target.getBoundingClientRect();
  var x = event.clientX - rectangle.left;
  var y = event.clientY - rectangle.top;

  channel.push("move_to", { x, y })
}
