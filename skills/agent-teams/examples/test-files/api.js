// API module
const express = require('express');

class ApiService {
    constructor(port = 3000) {
        this.app = express();
        this.port = port;
        this.routes = [];
    }

    init() {
        this.app.use(express.json());

        // Health check
        this.app.get('/health', (req, res) => {
            res.json({ status: 'ok', timestamp: Date.now() });
        });

        return this;
    }

    addRoute(method, path, handler) {
        this.routes.push({ method, path });
        this.app[method.toLowerCase()](path, handler);
    }

    start() {
        return new Promise((resolve) => {
            this.server = this.app.listen(this.port, () => {
                console.log(`API server listening on port ${this.port}`);
                resolve();
            });
        });
    }

    stop() {
        if (this.server) {
            this.server.close();
        }
    }
}

module.exports = ApiService;
