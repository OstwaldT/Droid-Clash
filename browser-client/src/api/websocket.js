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
    // Phase buffered from game_state_update; applied only when round_ready arrives
    this.pendingPhase = null;
    // Hand buffered from hand_update mid-round; applied only when round_ready arrives
    this.pendingHand = null;
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
      case "hand_update":
        this.handleHandUpdate(data);
        break;
      case "game_state_update":
        this.handleGameStateUpdate(data);
        break;
      case "player_statuses_update":
        this.handlePlayerStatusesUpdate(data);
        break;
      case "round_ready":
        this.handleRoundReady();
        break;
      case "game_over":
        this.handleGameOver(data);
        break;
      case "rematch_status":
        this.handleRematchStatus(data);
        break;
      case "countdown":
        this.handleCountdown(data);
        break;
      case "error":
        this.handleError(data);
        break;
    }
  }

  handleConnect(data) {
    const gameStore = useGameStore();
    gameStore.reset();  // Clear any stale state from a previous game
    this.pendingHand = null;
    this.pendingPhase = null;
    const playerStore = usePlayerStore();
    playerStore.setPlayer(data.playerId, playerStore.playerName);
    if (data.color) playerStore.setColor(data.color);
    playerStore.setConnected(true);
  }

  handlePlayerJoined(data) {
    const gameStore = useGameStore();
    gameStore.players = data.players;
  }

  handleGameStart(data) {
    const gameStore = useGameStore();
    gameStore.countdown = null;  // clear any active countdown
    gameStore.rematchPlayers = [];  // clear any stale rematch state
    gameStore.setGameState({
      gameId: data.gameId,
      phase: "card_selection",
      turnNumber: data.turnNumber,
      boardRadius: data.boardRadius,
      players: data.robots.map((r) => ({ ...r, name: r.name })),
      robots: data.robots,
    });
    if (data.playerStatuses) {
      gameStore.setPlayerStatuses(data.playerStatuses);
    }
    if (data.turnOrder) {
      gameStore.turnOrder = data.turnOrder;
    }
    // Hand arrives via a separate hand_update message
  }

  handleHandUpdate(data) {
    const gameStore = useGameStore();
    // If the player has submitted their turn, animations are about to play —
    // buffer the new hand and apply it only when round_ready fires.
    if (gameStore.turnSubmitted) {
      this.pendingHand = data;
    } else {
      gameStore.setAvailableCards(data.hand, data.counts ?? null);
    }
  }

  handleGameStateUpdate(data) {
    const gameStore = useGameStore();
    gameStore.robots = data.robots;
    gameStore.turnNumber = data.turnNumber;
    // Buffer the phase — don't switch yet; wait for round_ready (sent after
    // board animations complete) so players stay on the waiting screen during animation.
    this.pendingPhase = data.currentPhase || "card_selection";
    if (data.playerStatuses) {
      gameStore.setPlayerStatuses(data.playerStatuses);
    }
    if (data.turnOrder) {
      gameStore.turnOrder = data.turnOrder;
    }
  }

  // Called when the server signals that all board animations have finished.
  // Snapshots selected cards so CardSelection can animate them to the discard pile,
  // then deal the new hand. Safety fallback fires after 2s if component doesn't respond.
  handleRoundReady() {
    const gameStore = useGameStore();
    if (this.pendingPhase) {
      gameStore.phase = this.pendingPhase;
      this.pendingPhase = null;
    }
    if (this.pendingHand) {
      gameStore.setAvailableCards(this.pendingHand.hand, this.pendingHand.counts ?? null);
      this.pendingHand = null;
    }
    gameStore.snapshotDiscardCards();
    // Fallback: if the component doesn't call finishDiscard within 2s, force it
    setTimeout(() => {
      if (gameStore.discardingCards.length > 0) gameStore.finishDiscard();
    }, 2000);
  }

  handleGameOver(data) {
    const gameStore = useGameStore();
    gameStore.winnerId   = data.winner     ?? null;
    gameStore.winnerName = data.winnerName ?? null;
    if (data.finalPlayers) gameStore.robots = data.finalPlayers;
  }

  handlePlayerStatusesUpdate(data) {
    const gameStore = useGameStore();
    if (data.playerStatuses) {
      gameStore.setPlayerStatuses(data.playerStatuses);
    }
  }

  handleCountdown(data) {
    const gameStore = useGameStore();
    gameStore.countdown = data.seconds;
  }

  handleRematchStatus(data) {
    const gameStore = useGameStore();
    gameStore.rematchPlayers = data.requestingPlayers || [];
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
