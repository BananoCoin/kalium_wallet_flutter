import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/model/vault.dart';
import 'package:kalium_wallet_flutter/model/db/account.dart';
import 'package:kalium_wallet_flutter/model/db/contact.dart';
import 'package:kalium_wallet_flutter/util/nanoutil.dart';

class DBHelper {
  static const int DB_VERSION = 3;
  static const String CONTACTS_SQL = """CREATE TABLE Contacts( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT, 
        address TEXT, 
        monkey_path TEXT)""";
  static const String ACCOUNTS_SQL = """CREATE TABLE Accounts( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT, 
        acct_index INTEGER, 
        selected INTEGER, 
        last_accessed INTEGER,
        private_key TEXT,
        balance TEXT)""";
  static const String ACCOUNTS_ADD_ACCOUNT_COLUMN_SQL = """
    ALTER TABLE Accounts ADD address TEXT
    """;
  static Database _db;

  NanoUtil _nanoUtil;

  DBHelper() {
    _nanoUtil = NanoUtil();
  }

  Future<Database> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "kalium.db");
    var theDb = await openDatabase(path,
        version: DB_VERSION, onCreate: _onCreate, onUpgrade: _onUpgrade);
    return theDb;
  }

  void _onCreate(Database db, int version) async {
    // When creating the db, create the tables
    await db.execute(CONTACTS_SQL);
    await db.execute(ACCOUNTS_SQL);
    await db.execute(ACCOUNTS_ADD_ACCOUNT_COLUMN_SQL);
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion == 1) {
      // Add accounts table
      await db.execute(ACCOUNTS_SQL);
      await db.execute(ACCOUNTS_ADD_ACCOUNT_COLUMN_SQL);
    } else if (oldVersion == 2) {
      await db.execute(ACCOUNTS_ADD_ACCOUNT_COLUMN_SQL);
    }
  }

  // Contacts
  Future<List<Contact>> getContacts() async {
    var dbClient = await db;
    List<Map> list =
        await dbClient.rawQuery('SELECT * FROM Contacts ORDER BY name');
    List<Contact> contacts = new List();
    for (int i = 0; i < list.length; i++) {
      contacts.add(new Contact(
          id: list[i]["id"],
          name: list[i]["name"],
          address: list[i]["address"],
          monkeyPath: list[i]["monkey_path"]));
    }
    return contacts;
  }

  Future<List<Contact>> getContactsWithNameLike(String pattern) async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery(
        'SELECT * FROM Contacts WHERE name LIKE \'%$pattern%\' ORDER BY LOWER(name)');
    List<Contact> contacts = new List();
    for (int i = 0; i < list.length; i++) {
      contacts.add(new Contact(
          id: list[i]["id"],
          name: list[i]["name"],
          address: list[i]["address"],
          monkeyPath: list[i]["monkey_path"]));
    }
    return contacts;
  }

  Future<Contact> getContactWithAddress(String address) async {
    var dbClient = await db;
    List<Map> list = await dbClient
        .rawQuery('SELECT * FROM Contacts WHERE address = ?', [address]);
    if (list.length > 0) {
      return Contact(
          id: list[0]["id"],
          name: list[0]["name"],
          address: list[0]["address"],
          monkeyPath: list[0]["monkey_path"]);
    }
    return null;
  }

  Future<Contact> getContactWithName(String name) async {
    var dbClient = await db;
    List<Map> list = await dbClient
        .rawQuery('SELECT * FROM Contacts WHERE name = ?', [name]);
    if (list.length > 0) {
      return Contact(
          id: list[0]["id"],
          name: list[0]["name"],
          address: list[0]["address"],
          monkeyPath: list[0]["monkey_path"]);
    }
    return null;
  }

  Future<bool> contactExistsWithName(String name) async {
    var dbClient = await db;
    int count = Sqflite.firstIntValue(await dbClient.rawQuery(
        'SELECT count(*) FROM Contacts WHERE lower(name) = ?',
        [name.toLowerCase()]));
    return count > 0;
  }

  Future<bool> contactExistsWithAddress(String address) async {
    var dbClient = await db;
    int count = Sqflite.firstIntValue(await dbClient.rawQuery(
        'SELECT count(*) FROM Contacts WHERE lower(address) = ?',
        [address.toLowerCase()]));
    return count > 0;
  }

  Future<int> saveContact(Contact contact) async {
    var dbClient = await db;
    return await dbClient.rawInsert(
        'INSERT INTO Contacts (name, address) values(?, ?)',
        [contact.name, contact.address]);
  }

  Future<int> saveContacts(List<Contact> contacts) async {
    int count = 0;
    for (Contact c in contacts) {
      if (await saveContact(c) > 0) {
        count++;
      }
    }
    return count;
  }

  Future<bool> deleteContact(Contact contact) async {
    var dbClient = await db;
    return await dbClient.rawDelete(
            "DELETE FROM Contacts WHERE name = ? AND address = ?",
            [contact.name, contact.address]) >
        0;
  }

  Future<bool> setMonkeyForContact(Contact contact, String monkeyPath) async {
    var dbClient = await db;
    return await dbClient.rawUpdate(
            "UPDATE contacts SET monkey_path = ? WHERE address = ?",
            [monkeyPath, contact.address]) >
        0;
  }

  // Accounts
  Future<List<Account>> getAccounts() async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery("""SELECT * FROM Accounts 
ORDER BY 
    CASE 
        WHEN acct_index >= 0 THEN 0
        ELSE 1 
    END,
    CASE 
        WHEN acct_index >= 0 THEN acct_index 
        ELSE id 
    END;
""");
    List<Account> accounts = new List();
    for (int i = 0; i < list.length; i++) {
      accounts.add(Account(
          id: list[i]["id"],
          name: list[i]["name"],
          index: list[i]["acct_index"],
          lastAccess: list[i]["last_accessed"],
          address: list[i]["address"],
          selected: list[i]["selected"] == 1 ? true : false,
          balance: list[i]["balance"]));
    }
    for (Account a in accounts) {
      if (a.index > -1) {
        a.address =
            NanoUtil.seedToAddress(await sl.get<Vault>().getSeed(), a.index);
      }
    }
    return accounts;
  }

  Future<List<Account>> getRecentlyUsedAccounts({int limit = 2}) async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery(
        'SELECT * FROM Accounts WHERE selected != 1 ORDER BY last_accessed DESC, id ASC LIMIT ?',
        [limit]);
    List<Account> accounts = new List();
    for (int i = 0; i < list.length; i++) {
      accounts.add(Account(
          id: list[i]["id"],
          name: list[i]["name"],
          index: list[i]["acct_index"],
          lastAccess: list[i]["last_accessed"],
          selected: list[i]["selected"] == 1 ? true : false,
          address: list[i]["address"],
          balance: list[i]["balance"]));
    }
    for (Account a in accounts) {
      if (a.index > -1) {
        a.address =
            NanoUtil.seedToAddress(await sl.get<Vault>().getSeed(), a.index);
      }
    }
    return accounts;
  }

  Future<Account> addAccount({String nameBuilder}) async {
    var dbClient = await db;
    int newAccountId;
    Account account;
    await dbClient.transaction((Transaction txn) async {
      int nextIndex = 1; // Default starting index
      List<Map> accounts = await txn.rawQuery(
          'SELECT * FROM Accounts WHERE acct_index >= 0 ORDER BY acct_index ASC');

      for (int i = 0; i < accounts.length; i++) {
        if (accounts[i]["acct_index"] > nextIndex) {
          break;
        } else {
          nextIndex = accounts[i]["acct_index"] + 1;
        }
      }

      String nextName = nameBuilder.replaceAll("%1", nextIndex.toString());
      account = Account(
          id: 0,
          index: nextIndex,
          name: nextName,
          lastAccess: 0,
          selected: false,
          address: NanoUtil.seedToAddress(
              await sl.get<Vault>().getSeed(), nextIndex));
      newAccountId = await txn.rawInsert(
          'INSERT INTO Accounts (name, acct_index, last_accessed, selected, address) values(?, ?, ?, ?, ?)',
          [
            account.name,
            account.index,
            account.lastAccess,
            account.selected ? 1 : 0,
            account.address
          ]);
      account.id = newAccountId;
    });
    return account;
  }

  // See if account exists with private key
  Future<bool> accountExists(String privateKey) async {
    var dbClient = await db;
    String address = NanoUtil.privateToAddress(privateKey).toLowerCase();
    int count = Sqflite.firstIntValue(await dbClient.rawQuery(
        'SELECT count(*) FROM Accounts WHERE lower(address) = ?',
        [address.toLowerCase()]));
    return count > 0;
  }

  Future<Account> addAccountWithPrivateKey(
      {String accountName, String privateKey}) async {
    var dbClient = await db;
    Account account;
    int newAccountId;
    await dbClient.transaction((Transaction txn) async {
      String address = NanoUtil.privateToAddress(privateKey);
      account = Account(
          id: 0,
          index: -1,
          name: accountName,
          lastAccess: 0,
          selected: false,
          address: address);
      await sl.get<Vault>().setPrivateKey(address, privateKey);
      newAccountId = await txn.rawInsert(
          'INSERT INTO Accounts (name, acct_index, last_accessed, selected, address) values(?, ?, ?, ?, ?)',
          [
            account.name,
            -1,
            account.lastAccess,
            account.selected ? 1 : 0,
            account.address
          ]);
      account.id = newAccountId;
    });
    return account;
  }

  Future<int> deleteAccount(Account account) async {
    var dbClient = await db;
    if (account.index < 0) {
      await sl.get<Vault>().deletePrivateKey(account.address);
    }
    return await dbClient
        .rawDelete('DELETE FROM Accounts WHERE id = ?', [account.id]);
  }

  Future<int> saveAccount(Account account) async {
    var dbClient = await db;
    return await dbClient.rawInsert(
        'INSERT INTO Accounts (name, acct_index, last_accessed, selected, address) values(?, ?, ?, ?, ?)',
        [
          account.name,
          account.index,
          account.lastAccess,
          account.selected ? 1 : 0,
          account.address
        ]);
  }

  Future<int> changeAccountName(Account account, String name) async {
    var dbClient = await db;
    return await dbClient.rawUpdate(
        'UPDATE Accounts SET name = ? WHERE id = ?', [name, account.id]);
  }

  Future<void> changeToDefaultAccount() async {
    var dbClient = await db;
    return await dbClient.transaction((Transaction txn) async {
      await txn.rawUpdate('UPDATE Accounts set selected = 0');
      await txn
          .rawUpdate('UPDATE Accounts set selected = 1 where acct_index = 0');
      // Get access increment count
      List<Map> list = await txn
          .rawQuery('SELECT max(last_accessed) as last_access FROM Accounts');
      await txn.rawUpdate(
          'UPDATE Accounts set selected = ?, last_accessed = ? where acct_index = ?',
          [1, list[0]["last_access"] + 1, 0]);
    });
  }

  Future<void> changeAccount(Account account) async {
    var dbClient = await db;
    return await dbClient.transaction((Transaction txn) async {
      await txn.rawUpdate('UPDATE Accounts set selected = 0');
      // Get access increment count
      List<Map> list = await txn
          .rawQuery('SELECT max(last_accessed) as last_access FROM Accounts');
      await txn.rawUpdate(
          'UPDATE Accounts set selected = ?, last_accessed = ? where id = ?',
          [1, list[0]["last_access"] + 1, account.id]);
    });
  }

  Future<void> updateAccountBalance(Account account, String balance) async {
    var dbClient = await db;
    return await dbClient.rawUpdate(
        'UPDATE Accounts set balance = ? where id = ?', [balance, account.id]);
  }

  Future<Account> getSelectedAccount() async {
    var dbClient = await db;
    List<Map> list =
        await dbClient.rawQuery('SELECT * FROM Accounts where selected = 1');
    if (list.length == 0) {
      return null;
    }
    String address;
    if (list[0]["acct_index"] > -1) {
      address = NanoUtil.seedToAddress(
          await sl.get<Vault>().getSeed(), list[0]["acct_index"]);
    } else {
      address = list[0]["address"];
    }
    Account account = Account(
        id: list[0]["id"],
        name: list[0]["name"],
        index: list[0]["acct_index"],
        selected: true,
        lastAccess: list[0]["last_accessed"],
        balance: list[0]["balance"],
        address: address);
    return account;
  }

  Future<Account> getMainAccount() async {
    var dbClient = await db;
    List<Map> list =
        await dbClient.rawQuery('SELECT * FROM Accounts where acct_index = 0');
    if (list.length == 0) {
      return null;
    }
    String address = NanoUtil.seedToAddress(
        await sl.get<Vault>().getSeed(), list[0]["acct_index"]);
    Account account = Account(
        id: list[0]["id"],
        name: list[0]["name"],
        index: list[0]["acct_index"],
        selected: true,
        lastAccess: list[0]["last_accessed"],
        balance: list[0]["balance"],
        address: address);
    return account;
  }

  Future<void> dropAccounts() async {
    var dbClient = await db;
    return await dbClient.rawDelete('DELETE FROM ACCOUNTS');
  }
}
