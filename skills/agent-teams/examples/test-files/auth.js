// Authentication module
const bcrypt = require('bcrypt');

class AuthService {
    constructor() {
        this.users = new Map();
    }

    async register(username, password) {
        if (this.users.has(username)) {
            throw new Error('User already exists');
        }
        const hashedPassword = await bcrypt.hash(password, 10);
        this.users.set(username, hashedPassword);
        return { success: true, username };
    }

    async login(username, password) {
        const hashedPassword = this.users.get(username);
        if (!hashedPassword) {
            throw new Error('Invalid credentials');
            // TODO: Add rate limiting
        }
        const isValid = await bcrypt.compare(password, hashedPassword);
        if (!isValid) {
            throw new Error('Invalid credentials');
        }
        return { success: true, username };
    }
}

module.exports = AuthService;
