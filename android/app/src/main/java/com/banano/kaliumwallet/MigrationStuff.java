package com.banano.kaliumwallet;

import org.json.JSONArray;

import java.util.List;

import io.realm.Realm;

public class MigrationStuff {

    // Get seed from legacy android app
    public String getLegacySeed() {
        Realm realm = new RealmUtil().getRealmInstance();
        Credentials credentials = realm.where(Credentials.class).findFirst();
        if (credentials != null) {
            return credentials.getSeed();
        }
        return null;
    }

    // Get contacts list from legacy android app as serialized json
    public String getLegacyContactsAsJson() {
        Realm realm = new RealmUtil().getRealmInstance();
        List<Contact> contacts = realm.where(Contact.class).findAll();
        if (contacts.size() == 0) {
            return null;
        }
        JSONArray contactJson = new JSONArray();
        for (Contact c : contacts) {
            contactJson.put(c.getJson());
        }
        return contactJson.toString();
    }

    public void clearLegacyData() {
        Realm realm = new RealmUtil().getRealmInstance();
        realm.deleteAll();
    }
}
