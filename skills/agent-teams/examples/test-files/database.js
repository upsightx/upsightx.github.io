// Database module
const sqlite3 = require('sqlite3').verbose();

class DatabaseService {
    constructor(dbPath) {
        this.db = new sqlite3.Database(dbPath);
    }

    async query(sql, params = []) {
        return new Promise((resolve, reject) => {
            this.db.all(sql, params, (err, rows) => {
                if (err) reject(err);
                else resolve(rows);
            });
        });
    }

    async insert(table, data) {
        const keys = Object.keys(data);
        const values = Object.values(data);
        const placeholders = keys.map(() => '?').join(',');

        const sql = `INSERT INTO ${table} (${keys.join(',')}) VALUES (${placeholders})`;

        return new Promise((resolve, reject) => {
            this.db.run(sql, values, function(err) {
                if (err) reject(err);
                else resolve({ id: this.lastID });
            });
        });
    }

    close() {
        this.db.close();
    }
}

module.exports = DatabaseService;
