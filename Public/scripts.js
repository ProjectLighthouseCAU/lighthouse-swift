const lighthouseRows = 14;
const lighthouseCols = 28;
const xScale = 14;
const yScale = 2 * xScale;

let connection = null;
let auth = null;
let display = null;

function updateDisplay(rgb) {
    const ctx = display.getContext("2d");

    for (let i = 0; i < (rgb.length / 3); i++) {
        const r = rgb[3 * i];
        const g = rgb[3 * i + 1];
        const b = rgb[3 * i + 2];

        const y = Math.floor(i / lighthouseCols);
        const x = i % lighthouseCols;

        ctx.fillStyle = `rgb(${r},${g},${b})`;
        ctx.fillRect(x * xScale, y * yScale, xScale, yScale);
    }
}

function setUpDisplay() {
    display = document.getElementById("display");
    display.width = xScale * lighthouseCols;
    display.height = yScale * lighthouseRows;
    updateDisplay(new Uint8Array(3 * lighthouseRows * lighthouseCols));
}

function setUpConnection() {
    connection = new WebSocket(`${location.origin.replace(/^http/, "ws")}/websocket`);
    connection.binaryType = "arraybuffer";

    connection.addEventListener("open", () => {
        console.log("Connected!");
    });

    connection.addEventListener("message", event => {
        try {
            const message = MessagePack.decode(new Uint8Array(event.data));

            if (message.PAYL instanceof Uint8Array) {
                updateDisplay(message.PAYL);
            } else {
                console.log(`Something else: ${message.PAYL instanceof Uint8Array}`);
            }
        } catch (e) {
            console.log(`Error while decoding message from WebSocket: ${e}`);
        }
    });
}

function setUpFormListener() {
    const form = document.getElementById("auth-form");
    const fieldset = document.getElementById("auth-form-fieldset");
    const usernameField = document.getElementById("username");
    const tokenField = document.getElementById("token");

    form.addEventListener("submit", event => {
        event.preventDefault();

        if (auth) {
            alert("You are already authenticated!");
            return;
        }

        const username = usernameField.value;
        const token = tokenField.value;

        if (!username) {
            alert("Please provide a username!");
            return;
        }

        auth = { USER: username, TOKEN: token };
        fieldset.disabled = true;

        connection.send(MessagePack.encode({
            VERB: "STREAM",
            PATH: ["user", username, "model"],
            AUTH: auth,
            META: {},
            REID: 0,
            PAYL: null,
        }));
    });
}

window.addEventListener("load", () => {
    setUpDisplay();
    setUpConnection();
    setUpFormListener();
});
