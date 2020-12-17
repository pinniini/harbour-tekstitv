.pragma library

.import QtQuick.LocalStorage 2.0 as Sql

var initialized = false;
var dbName = "HarbourTekstiTV";
var dbVer = "1.0";
var dbDescr = "Harbour TekstiTV -database.";
var dbSize = 1000000;

// ----------------------------------------------------------
// Database handling.

// Initializes the database.
function initializeDatabase()
{
    console.log("Initializing database...")
    var db = Sql.LocalStorage.openDatabaseSync(dbName, dbVer, dbDescr, dbSize);
    db.transaction(
                function(tx) {
                    // Create Favorite-table if it doesn't already exist.
                    tx.executeSql('CREATE TABLE IF NOT EXISTS Favorite(caption TEXT, source TEXT, pageNumber INT, subPageNumber INT)');

                    // Create Setting-table.
                    tx.executeSql('CREATE TABLE IF NOT EXISTS Setting(name TEXT, value TEXT, source TEXT)');
                }
                )
    console.log("Database initialized...")
    initialized = true
}

// Returns the database or false if database is not initialized and for some reason initializing does not work.
function getDatabase()
{
    console.log("Getting database...")
    // Check if the database is initialized or not.
    if(!initialized)
    {
        console.log("Database not initialized...")
        initializeDatabase()

        if(initialized)
        {
            var db = Sql.LocalStorage.openDatabaseSync(dbName, dbVer, dbDescr, dbSize);
            return db
        }
        else
            return false
    }
    else // Database initialized.
    {
        var dab = Sql.LocalStorage.openDatabaseSync(dbName, dbVer, dbDescr, dbSize);
        return dab
    }
}

function getFavorites(source) {
    var db = getDatabase();
    var items;

    if(db) {
        db.transaction(function(tx) {
            var res = tx.executeSql('SELECT rowid, caption, source, pageNumber, subPageNumber FROM Favorite WHERE source=? ORDER BY pageNumber, subPageNumber', [source]);
            items = res.rows;
        });
    }

    return items;
}

function addFavorite(favorite) {
    var db = getDatabase();
    var itemId = -1;

    if(db) {
        db.transaction(function(tx) {
            var res = tx.executeSql('INSERT INTO Favorite VALUES(?, ?, ?, ?)', [favorite.caption, favorite.source, favorite.pageNumber, favorite.subPageNumber]);
            var id = parseInt(res.insertId);
            if(id !== NaN) {
                itemId = id;
            }
        });
    }

    return itemId;
}

function deleteFavorite(itemId) {
    var db = getDatabase();
    var rowsAffected = -1;

    if(db) {
        db.transaction(function(tx) {
            var res = tx.executeSql('DELETE FROM Favorite WHERE rowid=?', [itemId]);
            rowsAffected = res.rowsAffected;
        });
    }

    return rowsAffected === 1;
}

function doesFavoriteExist(source, pageNumber, subPageNumber) {
    var db = getDatabase();
    var exists = false;

    if(db) {
        db.transaction(function(tx) {
            var res = tx.executeSql('SELECT rowid FROM Favorite WHERE source=? and pageNumber=? and subPageNumber=?', [source, pageNumber, subPageNumber]);
            if(res.rows.length > 0) {
                exists = true;
            }
        });
    }

    return exists;
}

function getSettings() {
    var db = getDatabase();
    var items;

    if(db) {
        db.transaction(function(tx) {
            var res = tx.executeSql('SELECT name, value, source FROM Setting');
            items = res.rows;
        });
    }

    return items;
}

function getSetting(name, source) {
    var db = getDatabase();
    var setting = null;

    if (db) {
        db.transaction(function(tx) {
            var res = tx.executeSql('SELECT name, value, source FROM Setting WHERE name=? and source=?', [name, source]);

            if (res.rows.length === 1) {
                setting = res.rows[0];
            }
        });
    }

    return setting;
}

function upsertSetting(name, value, source) {
    var db = getDatabase()
    var id = -1

    if (db) {
        var changedCount = 0
        db.transaction(
            function(tx) {
                var result = tx.executeSql('SELECT rowid AS id FROM Setting WHERE name=? and source=?', [name, source])

                // No rows found -> insert.
                if (result.rows.length === 0) {
                    var res = tx.executeSql('INSERT INTO Setting (name, value, source) VALUES (?,?,?)', [name, value, source])
                    id = parseInt(res.insertId)
                }
                // Row found -> update.
                else {
                    var resu = tx.executeSql('UPDATE Setting SET value=? where name=? and source=?', [value, name, source])
                    if (resu.rowsAffected === 1) {
                        id = result.rows[0].id
                    }
                }
            }
        )
    }

    return id;
}

function deleteInitialSource() {
    var db = getDatabase()

    if (db) {
        db.transaction(
            function(tx) {
                var result = tx.executeSql('DELETE FROM Setting WHERE name=? and source=?', ['InitialSource', 'default']);
            }
        )
    }
}
