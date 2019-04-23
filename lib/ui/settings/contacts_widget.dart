import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:event_taxi/event_taxi.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';
import 'package:share/share.dart';
import 'package:flare_flutter/flare_actor.dart';

import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/dimens.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/app_icons.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/bus/events.dart';
import 'package:kalium_wallet_flutter/model/address.dart';
import 'package:kalium_wallet_flutter/model/db/appdb.dart';
import 'package:kalium_wallet_flutter/model/db/contact.dart';
import 'package:kalium_wallet_flutter/ui/contacts/add_contact.dart';
import 'package:kalium_wallet_flutter/ui/contacts/contact_details.dart';
import 'package:kalium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/util/fileutil.dart';

class ContactsList extends StatefulWidget {
  final AnimationController contactsController;
  bool contactsOpen;

  ContactsList(this.contactsController, this.contactsOpen);

  _ContactsListState createState() => _ContactsListState();
}

class _ContactsListState extends State<ContactsList> {
  final log = Logger("ContactsList");

  List<Contact> _contacts;
  String documentsDirectory;

  @override void initState() {
    super.initState();
    // Initial contacts list
    _contacts = List();
    getApplicationDocumentsDirectory().then((directory) {
      documentsDirectory = directory.path;
      setState(() {
        documentsDirectory = directory.path;
      });
      _updateContacts();
    });
  }

  @override void dispose() {
    if (_contactAddedSub != null) {
      _contactAddedSub.cancel();
    }
    if (_contactRemovedSub != null) {
      _contactRemovedSub.cancel();
    }
    super.dispose();
  }

  StreamSubscription<ContactAddedEvent> _contactAddedSub;
  StreamSubscription<ContactRemovedEvent> _contactRemovedSub;

  void _registerBus() {
    // Contact added bus event
    _contactAddedSub = EventTaxiImpl.singleton()
        .registerTo<ContactAddedEvent>()
        .listen((event) {
      setState(() {
        _contacts.add(event.contact);
        //Sort by name
        _contacts.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      });
      // Full update which includes downloading new monKey
      _updateContacts();
    });
    // Contact removed bus event
    _contactRemovedSub = EventTaxiImpl.singleton()
        .registerTo<ContactRemovedEvent>()
        .listen((event) {
      setState(() {
        _contacts.remove(event.contact);
      });
    });    
  }

  Future<void> _updateContacts() async {
    List<Contact> contacts = await sl.get<DBHelper>().getContacts();
    for (Contact c in contacts) {
      if (!_contacts.contains(c)) {
        setState(() {
          _contacts.add(c);
        });
      }
    }
    // Re-sort list
    setState(() {
      _contacts
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
    // Get any monKeys that are missing
    for (Contact c in _contacts) {
      // Download monKeys if not existing
      if (c.monkeyPath == null || c.monkeyPath.contains(".png")) {
        File svgFile = await sl.get<UIUtil>().downloadOrRetrieveMonkey(
            context, c.address, MonkeySize.SVG);
        // TODO - Validate SVG
        setState(() {
          c.monkeyPath = path.basename(svgFile.path);
        });
        await sl.get<DBHelper>().setMonkeyForContact(c, c.monkeyPath);
      }
      if (c.monkeyImage == null) {
        File pngFile = await sl.get<UIUtil>().downloadOrRetrieveMonkey(
            context, c.address, MonkeySize.SMALL);
        if (await sl.get<FileUtil>().pngHasValidSignature(pngFile)) {
          setState(() {
            c.monkeyImage = Image.file(pngFile,
                width: smallScreen(context) ? 55 : 70,
                height: smallScreen(context) ? 55 : 70);
          });
        }
      }
    }
  }

  Future<void> _exportContacts() async {
    List<Contact> contacts = await sl.get<DBHelper>().getContacts();
    if (contacts.length == 0) {
      sl.get<UIUtil>().showSnackbar(
          AppLocalization.of(context).noContactsExport, context);
      return;
    }
    List<Map<String, dynamic>> jsonList = List();
    contacts.forEach((contact) {
      jsonList.add(contact.toJson());
    });
    DateTime exportTime = DateTime.now();
    String filename =
        "kaliumcontacts_${exportTime.year}${exportTime.month}${exportTime.day}${exportTime.hour}${exportTime.minute}${exportTime.second}.txt";
    Directory baseDirectory = await getApplicationDocumentsDirectory();
    File contactsFile = File("${baseDirectory.path}/$filename");
    await contactsFile.writeAsString(json.encode(jsonList));
    sl.get<UIUtil>().cancelLockEvent();
    Share.shareFile(contactsFile);
  }

  Future<void> _importContacts() async {
    sl.get<UIUtil>().cancelLockEvent();
    String filePath = await FilePicker.getFilePath(
        type: FileType.CUSTOM, fileExtension: "txt");
    File f = File(filePath);
    if (!await f.exists()) {
      sl.get<UIUtil>().showSnackbar(
          AppLocalization.of(context).contactsImportErr, context);
      return;
    }
    try {
      String contents = await f.readAsString();
      Iterable contactsJson = json.decode(contents);
      List<Contact> contacts = List();
      List<Contact> contactsToAdd = List();
      contactsJson.forEach((contact) {
        contacts.add(Contact.fromJson(contact));
      });
      for (Contact contact in contacts) {
        if (!await sl.get<DBHelper>().contactExistsWithName(contact.name) &&
            !await sl.get<DBHelper>().contactExistsWithAddress(contact.address)) {
          // Contact doesnt exist, make sure name and address are valid
          if (Address(contact.address).isValid()) {
            if (contact.name.startsWith("@") && contact.name.length <= 20) {
              contactsToAdd.add(contact);
            }
          }
        }
      }
      // Save all the new contacts and update states
      int numSaved = await sl.get<DBHelper>().saveContacts(contactsToAdd);
      if (numSaved > 0) {
        _updateContacts();
        EventTaxiImpl.singleton().fire(
            ContactModifiedEvent(contact: Contact(name: "", address: "")));
        sl.get<UIUtil>().showSnackbar(
            AppLocalization.of(context)
                .contactsImportSuccess
                .replaceAll("%1", numSaved.toString()),
            context);
      } else {
        sl.get<UIUtil>().showSnackbar(
            AppLocalization.of(context).noContactsImport, context);
      }
    } catch (e) {
      log.severe(e.toString());
      sl.get<UIUtil>().showSnackbar(
          AppLocalization.of(context).contactsImportErr, context);
      return;
    }
  }

  @override Widget build(BuildContext context) {
    return _buildContacts(context);
  }

  Widget _buildContacts(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StateContainer.of(context).curTheme.backgroundDark,
        boxShadow: [
          BoxShadow(
              color: StateContainer.of(context).curTheme.overlay30,
              offset: Offset(-5, 0),
              blurRadius: 20),
        ],
      ),
      child: SafeArea(
        minimum: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.035,
          top: 60,
        ),
        child: Column(
          children: <Widget>[
            // Back button and Contacts Text
            Container(
              margin: EdgeInsets.only(bottom: 10, top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      //Back button
                      Container(
                        height: 40,
                        width: 40,
                        margin: EdgeInsets.only(right: 10, left: 10),
                        child: FlatButton(
                            highlightColor:
                                StateContainer.of(context).curTheme.text15,
                            splashColor:
                                StateContainer.of(context).curTheme.text15,
                            onPressed: () {
                              setState(() {
                                widget.contactsOpen = false;
                              });
                              widget.contactsController.reverse();
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.0)),
                            padding: EdgeInsets.all(8.0),
                            child: Icon(AppIcons.back,
                                color: StateContainer.of(context).curTheme.text,
                                size: 24)),
                      ),
                      //Contacts Header Text
                      Text(
                        AppLocalization.of(context).contactsHeader,
                        style: AppStyles.textStyleSettingsHeader(context),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      //Import button
                      Container(
                        height: 40,
                        width: 40,
                        margin: EdgeInsets.only(right: 5),
                        child: FlatButton(
                            highlightColor:
                                StateContainer.of(context).curTheme.text15,
                            splashColor:
                                StateContainer.of(context).curTheme.text15,
                            onPressed: () {
                              _importContacts();
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.0)),
                            padding: EdgeInsets.all(8.0),
                            child: Icon(AppIcons.import_icon,
                                color: StateContainer.of(context).curTheme.text,
                                size: 24)),
                      ),
                      //Export button
                      Container(
                        height: 40,
                        width: 40,
                        margin: EdgeInsets.only(right: 20),
                        child: FlatButton(
                            highlightColor:
                                StateContainer.of(context).curTheme.text15,
                            splashColor:
                                StateContainer.of(context).curTheme.text15,
                            onPressed: () {
                              _exportContacts();
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.0)),
                            padding: EdgeInsets.all(8.0),
                            child: Icon(AppIcons.export_icon,
                                color: StateContainer.of(context).curTheme.text,
                                size: 24)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Contacts list + top and bottom gradients
            Expanded(
              child: Stack(
                children: <Widget>[
                  // Contacts list
                  ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(top: 15.0),
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      // Some disaster recovery if monKey is in DB, but doesnt exist in filesystem
                      if (_contacts[index].monkeyPath != null) {
                        File("$documentsDirectory/${_contacts[index].monkeyPath}")
                            .exists()
                            .then((exists) {
                          if (!exists) {
                            sl.get<DBHelper>().setMonkeyForContact(
                                _contacts[index], null);
                          }
                        });
                      }
                      // Build contact
                      return _buildSingleContact(context, _contacts[index]);
                    },
                  ),
                  //List Top Gradient End
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: 20.0,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            StateContainer.of(context).curTheme.backgroundDark,
                            StateContainer.of(context).curTheme.backgroundDark00
                          ],
                          begin: Alignment(0.5, -1.0),
                          end: Alignment(0.5, 1.0),
                        ),
                      ),
                    ),
                  ),
                  //List Bottom Gradient End
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 15.0,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            StateContainer.of(context)
                                .curTheme
                                .backgroundDark00,
                            StateContainer.of(context).curTheme.backgroundDark,
                          ],
                          begin: Alignment(0.5, -1.0),
                          end: Alignment(0.5, 1.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10),
              child: Row(
                children: <Widget>[
                  AppButton.buildAppButton(
                      context,
                      AppButtonType.TEXT_OUTLINE,
                      AppLocalization.of(context).addContact,
                      Dimens.BUTTON_BOTTOM_DIMENS, onPressed: () {
                    AddContactSheet().mainBottomSheet(context);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleContact(BuildContext context, Contact contact) {
    return FlatButton(
      highlightColor: StateContainer.of(context).curTheme.text15,
      splashColor: StateContainer.of(context).curTheme.text15,
      onPressed: () {
        ContactDetailsSheet(contact, documentsDirectory)
            .mainBottomSheet(context);
      },
      padding: EdgeInsets.all(0.0),
      child: Column(children: <Widget>[
        Divider(
          height: 2,
          color: StateContainer.of(context).curTheme.text15,
        ),
        // Main Container
        Container(
          padding: EdgeInsets.symmetric(vertical: 5.0),
          margin: new EdgeInsets.only(left: 20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              //Container for monKey
              contact.monkeyImage != null
                  ? contact.monkeyImage
                  : Container(
                      width: smallScreen(context) ? 55 : 70,
                      height: smallScreen(context) ? 55 : 70,
                      child: FlareActor(
                          "assets/monkey_placeholder_animation.flr",
                          animation: "main",
                          fit: BoxFit.contain,
                          color: StateContainer.of(context).curTheme.primary),
                    ),
              //Contact info
              Container(
                margin: EdgeInsets.only(left: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    //Contact name
                    Text(contact.name,
                        style: AppStyles.textStyleSettingItemHeader(context)),
                    //Contact address
                    Text(
                      Address(contact.address).getShortString(),
                      style: AppStyles.textStyleTransactionAddress(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}