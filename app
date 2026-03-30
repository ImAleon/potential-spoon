import eventlet
eventlet.monkey_patch()

from flask import Flask, render_template_string, request, redirect, session
from flask_socketio import SocketIO, send
import sqlite3

app = Flask(__name__)
app.secret_key = "secret"
socketio = SocketIO(app)

# --------------------
# HTML (Chat Page)
# --------------------
chat_page = """
<h2>Messenger - {{user}}</h2>

<div id="chat" style="height:300px; overflow:auto; border:1px solid black;"></div>

<input id="message" placeholder="Type message...">
<button onclick="sendMessage()">Send</button>

<script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.0.1/socket.io.js"></script>
<script>
var socket = io();

socket.on("message", function(msg){
    var chat = document.getElementById("chat");
    chat.innerHTML += "<p>" + msg + "</p>";
});

function sendMessage(){
    var input = document.getElementById("message");
    socket.send("{{user}}: " + input.value);
    input.value = "";
}
</script>

<a href="/home">Back</a>
"""

# --------------------
# Routes
# --------------------
@app.route("/chat")
def chat():
    if "user" not in session:
        return redirect("/")
    return render_template_string(chat_page, user=session["user"])

# --------------------
# Socket Events
# --------------------
@socketio.on("message")
def handle_message(msg):
    socketio.emit("message", msg, room="user123_room")

# --------------------
# Run
# --------------------
if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=10000)
