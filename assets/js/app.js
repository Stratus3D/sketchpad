import css from "../css/app.css"
import "phoenix_html"
import {Socket, Presence} from "phoenix"
import {Sketchpad, sanitize} from "./sketchpad"

let socket = new Socket("/socket", {
  params: {token: window.userToken},
  logger: function(kind, msg, data){
    console.log(`${kind}: ${msg}`, data)
  }
})

let App = {
  init(){
    socket.connect()
    this.padChannel = socket.channel("pad:lobby")
    this.el = document.getElementById("sketchpad")
    this.pad = new Sketchpad(this.el, window.username)

    this.bind()

    this.padChannel.join()
      .receive("ok", resp => console.log("joined!", resp))
      .receive("error", resp => console.log("failed to join", resp))
  },

  bind(){
    this.pad.on("stroke", data => this.padChannel.push("stroke", data))

    this.padChannel.on("stroke", ({user_id, stroke}) => {
      this.pad.putStroke(user_id, stroke, {color: "#000000"})
    })

    this.clearButton = document.getElementById("clear-button")
    this.exportButton = document.getElementById("export-button")

    this.clearButton.addEventListener("click", e => {
      e.preventDefault()
      this.padChannel.push("clear", {})
    })

    this.exportButton.addEventListener("click", e => {
      e.preventDefault()
      let win = window.open()
      win.document.write(`<img src="${this.pad.getImageURL()}"/>`)
    })

    this.padChannel.on("clear", () => this.pad.clear())

    this.msgInput = document.getElementById("message-input")
    this.msgContainer = document.getElementById("messages")

    this.msgInput.addEventListener("keypress", e => {
      if(e.keyCode !== 13){ return }
      let body = this.msgInput.value
      this.msgInput.disabled = true

      let onOk = () => {
        this.msgInput.disabled = false
        this.msgInput.value = ""
      }
      let onError = () => {
        this.msgInput.disabled = false
      }

      this.padChannel.push("new_message", {body})
        .receive("ok", onOk)
        .receive("error", onError)
        .receive("timeout", onError)
    })

    this.padChannel.on("new_message", ({user_id, body}) => {
      this.msgContainer.innerHTML +=
        `<br/><b>${sanitize(user_id)}</b>: ${sanitize(body)}`
      this.msgContainer.scrollTop = this.msgContainer.scrollHeight
    })

    this.userContainer = document.getElementById("users")
    let presence = new Presence(this.padChannel)
    presence.onJoin((id, current, newPres) => {
      if(!current){
        console.log(`${id} has entered the sketchpad`)
      } else {
        console.log(`${id} has joine from another device`)
      }
    })

    presence.onLeave((id, current, leftPres) => {
      if(current.metas.length === 0) {
        console.log(`${id} has left completely`)
      } else {
        console.log(`${id} has left from a device`)
      }
    })

    presence.onSync(() => this.renderUsers(presence))

    this.padChannel.on("request_png", () => {
      this.padChannel.push("png_ack", {png: this.pad.getImageURL()})
        .receive("ok", ({ascii}) => console.log(ascii))
    })
  },

  renderUsers(presence){
    let users = presence.list((id, {color, metas: [first, ...rest]}) => {
      first.color = color
      first.username = id
      first.numConnections = rest.length + 1
      return first
    })

    this.userContainer.innerHTML = users.map(user => {
      return `<br/><span style="color: ${sanitize(user.color)}">${sanitize(user.username)} (${user.numConnections})</span>`
    }).join("")
  }
}

if (window.userToken != "") {App.init()}
