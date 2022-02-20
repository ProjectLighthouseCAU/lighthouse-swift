let connection = null;
let auth = null;

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
                const display = document.getElementById("display");
                display.innerText = message.PAYL.map(x => `${x}`).join(", ");
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
    setUpConnection();
    setUpFormListener();
});
