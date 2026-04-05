import { usePlayerStore } from "@/stores/playerStore";
import { useGameStore } from "@/stores/gameStore";

const WS_URL = import.meta.env.DEV
  ? "ws://192.168.1.32:8080"
  : process.env.VITE_WS_URL || "ws://localhost:8080";

class WebSocketClient {
  constructor() {
    this.ws = null;
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 5;
    this.reconnectDelay = 1000;
    this.messageHandlers = {};
  }

  connect() {
    return new Promise((resolve, reject) => {
      try {
        this.ws = new WebSocket(WS_URL);

        this.ws.onopen = () => {
          console.log("Connected to WebSocket server");
          this.reconnectAttempts = 0;
          resolve();
        };

        this.ws.onmessage = (event) => {
          try {
            // Handle both text and binary data
            let data = event.data
            if (data instanceof Blob) {
              // Binary data - convert to text first
              const reader = new FileReader()
              reader.onload = () => {
                try {
                  const message = JSON.parse(reader.result)
                  this.handleMessage(message)
                } catch (error) {
                  console.error("Failed to parse message:", error)
                }
              }
              reader.readAsText(data)
            } else {
              // Text data - parse directly
              const message = JSON.parse(data)
              this.handleMessage(message)
            }
          } catch (error) {
            console.error("Failed to parse message:", error);
          }
        };

        this.ws.onerror = (error) => {
          console.error("WebSocket error:", error);
          reject(error);
        };

        this.ws.onclose = () => {
          console.log("Disconnected from server");
          const playerStore = usePlayerStore();
          playerStore.setConnected(false);
          this.attemptReconnect();
        };
      } catch (error) {
        reject(error);
      }
    });
  }

  attemptReconnect() {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      const delay =
        this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);
      console.log(
        `Reconnecting in ${delay}ms... (attempt ${this.reconnectAttempts})`,
      );
      setTimeout(() => this.connect().catch(console.error), delay);
    }
  }

  send(message) {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      console.error("WebSocket not connected");
      return false;
    }
    try {
      this.ws.send(
        JSON.stringify({
          ...message,
          timestamp: Date.now(),
        }),
      );
      return true;
    } catch (error) {
      console.error("Failed to send message:", error);
      return false;
    }
  }

  on(messageType, handler) {
    if (!this.messageHandlers[messageType]) {
      this.messageHandlers[messageType] = [];
    }
    this.messageHandlers[messageType].push(handler);
  }

  handleMessage(message) {
    const { type, data } = message;
    console.log("Received message:", type, data);

    if (this.messageHandlers[type]) {
      this.messageHandlers[type].forEach((handler) => {
        try {
          handler(data);
        } catch (error) {
          console.error(`Error handling message type ${type}:`, error);
        }
      });
    }

    // Handle common message types
    switch (type) {
      case "connect":
        this.handleConnect(data);
        break;
      case "player_joined":
        this.handlePlayerJoined(data);
        break;
      case "game_start":
        this.handleGameStart(data);
        break;
      case "game_state_update":
        this.handleGameStateUpdate(data);
        break;
      case "error":
        this.handleError(data);
        break;
    }
  }

  handleConnect(data) {
    const playerStore = usePlayerStore();
    playerStore.setPlayer(data.playerId, playerStore.playerName);
    playerStore.setConnected(true);
  }

  handlePlayerJoined(data) {
    const gameStore = useGameStore();
    gameStore.players = data.players;
  }

  handleGameStart(data) {
    const gameStore = useGameStore();
    gameStore.setGameState({
      gameId: data.gameId,
      phase: "card_selection",
      turnNumber: data.turnNumber,
      boardWidth: data.boardWidth,
      boardHeight: data.boardHeight,
      players: data.robots.map((r) => ({ ...r, name: r.name })),
      robots: data.robots,
    });
    gameStore.setAvailableCards(data.availableCards);
  }

  handleGameStateUpdate(data) {
    const gameStore = useGameStore();
    gameStore.robots = data.robots;
    gameStore.turnNumber = data.turnNumber;
    gameStore.phase = data.currentPhase || "card_selection";
  }

  handleError(data) {
    console.error("Server error:", data.code, data.message);
  }

  disconnect() {
    if (this.ws) {
      this.ws.close();
    }
  }
}

export default new WebSocketClient();
