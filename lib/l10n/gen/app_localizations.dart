import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application name, shown on the login card and as the task title
  ///
  /// In en, this message translates to:
  /// **'Planka'**
  String get appTitle;

  /// Button that accepts the server's terms of service
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get actionAccept;

  /// Button that confirms creating a new user
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// Button that dismisses a dialog without applying it
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Button that closes a dialog
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Button that confirms creating a project, board or label
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// Menu entry and button that deletes the selected item
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Menu entry that edits the selected item
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// Button that confirms moving a card to another list
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get actionMove;

  /// Button that removes a member, manager or avatar
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// Menu entry that renames the selected item
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// Tooltip on the button that restores an archived or trashed card
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get actionRestore;

  /// Button that re-runs a request that failed
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Button that confirms a text prompt or a credential change
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Button that picks a file to upload as the profile avatar
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get actionUpload;

  /// Label of the board picker in the move-card dialog
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get fieldBoard;

  /// Label of the email field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// Label of the list picker in the move-card dialog
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get fieldList;

  /// Label of the name field, and the name option in the list sort dialog
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// Label of the password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// Label of the project picker in the move-card dialog
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get fieldProject;

  /// Validation error shown under a login field left empty
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// Placeholder shown instead of a profile value the user has not set
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get valueNotSet;

  /// Shown instead of a member's name when that user is not in the loaded data
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownUser;

  /// Snackbar shown when the server rejects the email/username and password
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get errorInvalidCredentials;

  /// Subtitle under the app name on the login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to your server'**
  String get loginSubtitle;

  /// Label of the Planka server address field
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get loginServerUrl;

  /// Label of the login identity field
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get loginEmailOrUsername;

  /// Tooltip of the button that reveals the typed password
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get loginShowPassword;

  /// Tooltip of the button that masks the typed password
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get loginHidePassword;

  /// Button that submits the login form
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginSubmit;

  /// Snackbar shown when the stored session was rejected and the user is back on the login screen
  ///
  /// In en, this message translates to:
  /// **'Session expired — log in again'**
  String get loginSessionExpired;

  /// Title of the dialog shown when the server requires accepting its terms
  ///
  /// In en, this message translates to:
  /// **'Accept Terms of Service?'**
  String get loginTermsTitle;

  /// Body of the terms-of-service dialog
  ///
  /// In en, this message translates to:
  /// **'This server requires you to accept its Terms of Service to log in.'**
  String get loginTermsMessage;

  /// Title of the login step that asks for a two-factor code
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication'**
  String get loginTotpTitle;

  /// Body text of the two-factor code step, explaining that a recovery code is also accepted
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your authenticator app, or one of your recovery codes.'**
  String get loginTotpSubtitle;

  /// Label of the field that takes a two-factor or recovery code
  ///
  /// In en, this message translates to:
  /// **'Authentication code'**
  String get loginTotpCode;

  /// Button that submits the two-factor code
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get loginTotpVerify;

  /// Message shown on the two-factor step when the server rejects the submitted code
  ///
  /// In en, this message translates to:
  /// **'That code was rejected. Try again.'**
  String get loginTotpRejected;

  /// Message shown when the two-factor window closed and the user is back on the credentials step
  ///
  /// In en, this message translates to:
  /// **'Sign-in timed out. Enter your password again.'**
  String get loginTotpExpired;

  /// Title of the projects screen
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsTitle;

  /// Shown on the projects screen when the account has no projects
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get projectsEmpty;

  /// Tooltip of the app bar button that creates a project
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projectNewTooltip;

  /// Title of the create-project prompt
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projectNewTitle;

  /// Hint of the project name field
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectNameHint;

  /// Title of the rename-project prompt
  ///
  /// In en, this message translates to:
  /// **'Rename project'**
  String get projectRenameTitle;

  /// Title of the delete-project confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete project?'**
  String get projectDeleteTitle;

  /// Body of the delete-project confirmation
  ///
  /// In en, this message translates to:
  /// **'The project and all its boards will be permanently deleted.'**
  String get projectDeleteMessage;

  /// Project menu entry that creates a board
  ///
  /// In en, this message translates to:
  /// **'Add board'**
  String get projectMenuAddBoard;

  /// Project menu entry that opens the managers dialog
  ///
  /// In en, this message translates to:
  /// **'Managers'**
  String get projectMenuManagers;

  /// Project menu entry that opens the custom fields manager on its templates page
  ///
  /// In en, this message translates to:
  /// **'Custom fields'**
  String get projectMenuCustomFields;

  /// Project menu entry that opens the background picker
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get projectMenuBackground;

  /// Tooltip on the button that marks a project as a favorite
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get projectFavoriteAddTooltip;

  /// Tooltip on the button that clears a project's favorite mark
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get projectFavoriteRemoveTooltip;

  /// Title of the create-board prompt
  ///
  /// In en, this message translates to:
  /// **'New board'**
  String get boardNewTitle;

  /// Hint of the board name field
  ///
  /// In en, this message translates to:
  /// **'Board name'**
  String get boardNameHint;

  /// App bar title on the board screen while the board is still loading
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get boardFallbackTitle;

  /// Tooltip of the button that shows the card filter bar
  ///
  /// In en, this message translates to:
  /// **'Filter cards'**
  String get boardFilterTooltip;

  /// Hint of the card search field in the filter bar
  ///
  /// In en, this message translates to:
  /// **'Search cards…'**
  String get boardSearchHint;

  /// Board menu entry that renames the board
  ///
  /// In en, this message translates to:
  /// **'Rename board'**
  String get boardMenuRename;

  /// Board menu entry that deletes the board
  ///
  /// In en, this message translates to:
  /// **'Delete board'**
  String get boardMenuDelete;

  /// Title of the rename-board prompt
  ///
  /// In en, this message translates to:
  /// **'Rename board'**
  String get boardRenameTitle;

  /// Title of the delete-board confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete board?'**
  String get boardDeleteTitle;

  /// Body of the delete-board confirmation
  ///
  /// In en, this message translates to:
  /// **'The board and everything on it will be deleted.'**
  String get boardDeleteMessage;

  /// Banner shown while the board's realtime socket is down
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get boardReconnecting;

  /// Button that adds a list to the board
  ///
  /// In en, this message translates to:
  /// **'Add list'**
  String get listAdd;

  /// Hint of the list name field
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get listNameHint;

  /// Title of the rename-list prompt
  ///
  /// In en, this message translates to:
  /// **'Rename list'**
  String get listRenameTitle;

  /// Title of the delete-list confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete list?'**
  String get listDeleteTitle;

  /// Body of the delete-list confirmation
  ///
  /// In en, this message translates to:
  /// **'The list and all its cards will be deleted.'**
  String get listDeleteMessage;

  /// List menu entry that opens the sort picker
  ///
  /// In en, this message translates to:
  /// **'Sort by…'**
  String get listMenuSort;

  /// Title of the list sort dialog
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get listSortTitle;

  /// One row of the list sort dialog, combining a field with a direction
  ///
  /// In en, this message translates to:
  /// **'{field} ({order})'**
  String listSortOption(String field, String order);

  /// Sort the list by each card's due date
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get listSortFieldDueDate;

  /// Sort the list by when each card was created
  ///
  /// In en, this message translates to:
  /// **'Created date'**
  String get listSortFieldCreatedDate;

  /// Sort direction, lowercase because it appears in parentheses after the field
  ///
  /// In en, this message translates to:
  /// **'ascending'**
  String get listSortOrderAscending;

  /// Sort direction, lowercase because it appears in parentheses after the field
  ///
  /// In en, this message translates to:
  /// **'descending'**
  String get listSortOrderDescending;

  /// Button that adds a card to a list
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get cardAdd;

  /// Hint of the card name field
  ///
  /// In en, this message translates to:
  /// **'Card name'**
  String get cardNameHint;

  /// Shown in the card sheet when the card was deleted while it was open
  ///
  /// In en, this message translates to:
  /// **'Card no longer exists'**
  String get cardGone;

  /// Tooltip of the button that subscribes to a card's notifications
  ///
  /// In en, this message translates to:
  /// **'Watch card'**
  String get cardWatch;

  /// Tooltip of the button that unsubscribes from a card's notifications
  ///
  /// In en, this message translates to:
  /// **'Unwatch card'**
  String get cardUnwatch;

  /// Tooltip of the button that copies the card
  ///
  /// In en, this message translates to:
  /// **'Duplicate card'**
  String get cardDuplicate;

  /// Tooltip of the button that opens the move-card dialog
  ///
  /// In en, this message translates to:
  /// **'Move…'**
  String get cardMove;

  /// Tooltip of the button that moves the card to the board's archive
  ///
  /// In en, this message translates to:
  /// **'Archive card'**
  String get cardArchive;

  /// Tooltip of the button that moves the card to the board's trash
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get cardMoveToTrash;

  /// Tooltip of the button that deletes the card outright
  ///
  /// In en, this message translates to:
  /// **'Delete card'**
  String get cardDelete;

  /// Title of the delete-card confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete card?'**
  String get cardDeleteTitle;

  /// Body of the delete-card confirmation
  ///
  /// In en, this message translates to:
  /// **'This card will be permanently deleted.'**
  String get cardDeleteMessage;

  /// Placeholder shown in place of an empty card description
  ///
  /// In en, this message translates to:
  /// **'Add a description…'**
  String get cardDescriptionHint;

  /// Error shown when the platform cannot open a downloaded attachment
  ///
  /// In en, this message translates to:
  /// **'Could not open {name}: {message}'**
  String cardOpenAttachmentFailed(String name, String message);

  /// Title of the move-card dialog
  ///
  /// In en, this message translates to:
  /// **'Move card'**
  String get moveCardTitle;

  /// Card sheet section heading
  ///
  /// In en, this message translates to:
  /// **'Stopwatch'**
  String get sectionStopwatch;

  /// Card sheet section heading, and title of the manage-labels dialog
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get sectionLabels;

  /// Card sheet section heading, and board menu entry that opens the members dialog
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get sectionMembers;

  /// Card sheet section heading
  ///
  /// In en, this message translates to:
  /// **'Checklists'**
  String get sectionChecklists;

  /// Card sheet section heading
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get sectionAttachments;

  /// Card sheet section heading
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get sectionComments;

  /// Card sheet section heading
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get sectionActivity;

  /// Button shown in place of a due date the card does not have yet
  ///
  /// In en, this message translates to:
  /// **'Set due date'**
  String get dueDateSet;

  /// Tooltip of the button that clears the card's due date
  ///
  /// In en, this message translates to:
  /// **'Remove due date'**
  String get dueDateRemove;

  /// Button that starts timing a card that has no stopwatch yet
  ///
  /// In en, this message translates to:
  /// **'Start stopwatch'**
  String get stopwatchStart;

  /// Tooltip of the button that pauses a running stopwatch
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get stopwatchPause;

  /// Tooltip of the button that resumes a paused stopwatch
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get stopwatchResume;

  /// Tooltip of the button that clears the card's stopwatch
  ///
  /// In en, this message translates to:
  /// **'Reset stopwatch'**
  String get stopwatchReset;

  /// Chip that opens the manage-labels dialog
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get labelChip;

  /// Label of the field that names a label about to be created
  ///
  /// In en, this message translates to:
  /// **'New label name'**
  String get labelNewName;

  /// Title of the rename-label prompt
  ///
  /// In en, this message translates to:
  /// **'Rename label'**
  String get labelRenameTitle;

  /// Title of the delete-label confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete label?'**
  String get labelDeleteTitle;

  /// Body of the delete-label confirmation
  ///
  /// In en, this message translates to:
  /// **'The label is removed from the board and all cards.'**
  String get labelDeleteMessage;

  /// Button that adds a checklist to the card
  ///
  /// In en, this message translates to:
  /// **'Add checklist'**
  String get checklistAdd;

  /// Title of the rename-checklist prompt
  ///
  /// In en, this message translates to:
  /// **'Rename checklist'**
  String get checklistRenameTitle;

  /// Title of the delete-checklist confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete checklist?'**
  String get checklistDeleteTitle;

  /// Body of the delete-checklist confirmation
  ///
  /// In en, this message translates to:
  /// **'The checklist and its tasks will be deleted.'**
  String get checklistDeleteMessage;

  /// Button that adds a task to a checklist
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get taskAdd;

  /// Title of the rename-task prompt
  ///
  /// In en, this message translates to:
  /// **'Rename task'**
  String get taskRenameTitle;

  /// Title of the delete-task confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get taskDeleteTitle;

  /// Button that picks a file to attach to the card
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get attachmentAdd;

  /// Subtitle marking the attachment currently used as the card cover
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get attachmentCover;

  /// Menu entry that makes this attachment the card cover
  ///
  /// In en, this message translates to:
  /// **'Set as cover'**
  String get attachmentSetAsCover;

  /// Menu entry that clears the card cover
  ///
  /// In en, this message translates to:
  /// **'Remove cover'**
  String get attachmentRemoveCover;

  /// Hint of the new-comment field
  ///
  /// In en, this message translates to:
  /// **'Write a comment…'**
  String get commentHint;

  /// Tooltip of the button that posts the comment
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commentSend;

  /// Title of the edit-comment prompt
  ///
  /// In en, this message translates to:
  /// **'Edit comment'**
  String get commentEditTitle;

  /// Title of the delete-comment confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete comment?'**
  String get commentDeleteTitle;

  /// Shown in the activity section when its request failed
  ///
  /// In en, this message translates to:
  /// **'Could not load activity'**
  String get activityLoadError;

  /// Shown in the activity section when the card has no recorded actions
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get activityEmpty;

  /// One activity row: who acted, followed by what they did
  ///
  /// In en, this message translates to:
  /// **'{user} {description}'**
  String activityEntry(String user, String description);

  /// Stands in for the actor of an activity entry whose user is unknown
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get activitySomeone;

  /// Stands in for a card member the activity payload did not name
  ///
  /// In en, this message translates to:
  /// **'a member'**
  String get activityAMember;

  /// Stands in for a task the activity payload did not name
  ///
  /// In en, this message translates to:
  /// **'a task'**
  String get activityATask;

  /// Activity description, follows the actor's name
  ///
  /// In en, this message translates to:
  /// **'created this card'**
  String get activityCreatedCard;

  /// Activity description, follows the actor's name
  ///
  /// In en, this message translates to:
  /// **'created this card in {list}'**
  String activityCreatedCardInList(String list);

  /// Activity description, follows the actor's name
  ///
  /// In en, this message translates to:
  /// **'moved this card'**
  String get activityMovedCard;

  /// Activity description, follows the actor's name
  ///
  /// In en, this message translates to:
  /// **'moved this card from {from} to {to}'**
  String activityMovedCardFromTo(String from, String to);

  /// Activity description, follows the actor's name
  ///
  /// In en, this message translates to:
  /// **'added {member} to this card'**
  String activityAddedMember(String member);

  /// Activity description, follows the actor's name
  ///
  /// In en, this message translates to:
  /// **'removed {member} from this card'**
  String activityRemovedMember(String member);

  /// Activity description, follows the actor's name
  ///
  /// In en, this message translates to:
  /// **'completed {task}'**
  String activityCompletedTask(String task);

  /// Activity description, follows the actor's name
  ///
  /// In en, this message translates to:
  /// **'uncompleted {task}'**
  String activityUncompletedTask(String task);

  /// Activity description for an action type this client does not model
  ///
  /// In en, this message translates to:
  /// **'updated this card'**
  String get activityUpdatedCard;

  /// Title of the notifications screen
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Shown when the account has no notifications
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmpty;

  /// Button that marks every notification as read
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// Relative timestamp for something that happened under a minute ago
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// Short relative timestamp in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String timeMinutesAgo(int minutes);

  /// Short relative timestamp in hours
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String timeHoursAgo(int hours);

  /// Short relative timestamp in days
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String timeDaysAgo(int days);

  /// Title of the board members dialog
  ///
  /// In en, this message translates to:
  /// **'Board members'**
  String get boardMembersTitle;

  /// Heading of the list of users who can be added to the board
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get boardMemberAdd;

  /// Title of the remove-board-member confirmation
  ///
  /// In en, this message translates to:
  /// **'Remove member?'**
  String get boardMemberRemoveTitle;

  /// Body of the remove-board-member confirmation
  ///
  /// In en, this message translates to:
  /// **'They will lose access to this board.'**
  String get boardMemberRemoveMessage;

  /// Menu entry that promotes a board member to editor
  ///
  /// In en, this message translates to:
  /// **'Make editor'**
  String get boardMemberMakeEditor;

  /// Menu entry that demotes a board member to viewer
  ///
  /// In en, this message translates to:
  /// **'Make viewer'**
  String get boardMemberMakeViewer;

  /// Shown instead of the user list when the server refuses to list users
  ///
  /// In en, this message translates to:
  /// **'Adding members requires admin rights'**
  String get boardMembersAdminRequired;

  /// Shown when every known user is already on the board
  ///
  /// In en, this message translates to:
  /// **'Everyone is already a member'**
  String get boardMembersAllAdded;

  /// Board membership role, shown under a member's name
  ///
  /// In en, this message translates to:
  /// **'editor'**
  String get boardRoleEditor;

  /// Board membership role, shown under a member's name
  ///
  /// In en, this message translates to:
  /// **'viewer'**
  String get boardRoleViewer;

  /// Title of the project managers dialog
  ///
  /// In en, this message translates to:
  /// **'Project managers'**
  String get projectManagersTitle;

  /// Heading of the list of users who can be made managers
  ///
  /// In en, this message translates to:
  /// **'Add manager'**
  String get projectManagerAdd;

  /// Tooltip of the button that removes a project manager
  ///
  /// In en, this message translates to:
  /// **'Remove manager'**
  String get projectManagerRemoveTooltip;

  /// Title of the remove-manager confirmation
  ///
  /// In en, this message translates to:
  /// **'Remove manager?'**
  String get projectManagerRemoveTitle;

  /// Body of the remove-manager confirmation
  ///
  /// In en, this message translates to:
  /// **'They will lose manager access to this project.'**
  String get projectManagerRemoveMessage;

  /// Shown instead of the user list when the server refuses to list users
  ///
  /// In en, this message translates to:
  /// **'Adding managers requires admin rights'**
  String get projectManagersAdminRequired;

  /// Shown when every known user already manages the project
  ///
  /// In en, this message translates to:
  /// **'Everyone is already a manager'**
  String get projectManagersAllAdded;

  /// Title of the project background picker
  ///
  /// In en, this message translates to:
  /// **'Project background'**
  String get projectBackgroundTitle;

  /// Button that picks an image to use as the project background
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get projectBackgroundUploadImage;

  /// Button that clears the project background
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get projectBackgroundNone;

  /// Title of the profile dialog, and the account menu entry that opens it
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Label of the phone field
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// Label of the organization field
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get profileOrganization;

  /// Label of the username field
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profileUsername;

  /// Title of the dialog that changes the signed-in user's email
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get profileChangeEmail;

  /// Hint of the new email field
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get profileNewEmail;

  /// Title of the dialog that changes the signed-in user's username
  ///
  /// In en, this message translates to:
  /// **'Change username'**
  String get profileChangeUsername;

  /// Hint of the new username field
  ///
  /// In en, this message translates to:
  /// **'New username'**
  String get profileNewUsername;

  /// Title of the dialog that changes the signed-in user's password
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileChangePassword;

  /// Hint of the new password field
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get profileNewPassword;

  /// Hint of the field that confirms the change with the existing password
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get profileCurrentPassword;

  /// Title of the admin user management dialog, and the account menu entry that opens it
  ///
  /// In en, this message translates to:
  /// **'Manage users'**
  String get manageUsersTitle;

  /// Button and dialog title for creating a user
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get userAdd;

  /// Title of the delete-user confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete user?'**
  String get userDeleteTitle;

  /// Body of the delete-user confirmation
  ///
  /// In en, this message translates to:
  /// **'{name} will be permanently removed.'**
  String userDeleteMessage(String name);

  /// Menu entry that gives a user another role
  ///
  /// In en, this message translates to:
  /// **'Make {role}'**
  String userMakeRole(String role);

  /// Menu entry that suspends a user's access
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get userDeactivate;

  /// Menu entry that restores a suspended user's access
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get userReactivate;

  /// Planka user role granting full server administration
  ///
  /// In en, this message translates to:
  /// **'admin'**
  String get userRoleAdmin;

  /// Planka user role allowed to create projects
  ///
  /// In en, this message translates to:
  /// **'projectOwner'**
  String get userRoleProjectOwner;

  /// Planka user role limited to the boards they are a member of
  ///
  /// In en, this message translates to:
  /// **'boardUser'**
  String get userRoleBoardUser;

  /// Account menu entry that logs in to another server or user
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountAdd;

  /// Title of the archive/trash browser, and the board menu entry that opens it
  ///
  /// In en, this message translates to:
  /// **'Archive & trash'**
  String get archiveTrashTitle;

  /// Tab listing the board's archived cards
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveTab;

  /// Tab listing the board's trashed cards
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trashTab;

  /// Shown in a tab when the board has no archive or trash list at all
  ///
  /// In en, this message translates to:
  /// **'No list on this board'**
  String get archiveTrashNoList;

  /// Shown in a tab when the archive or trash list is empty
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get archiveTrashEmpty;

  /// Snackbar offering a newer release
  ///
  /// In en, this message translates to:
  /// **'Update available (v{version})'**
  String updateAvailable(String version);

  /// Snackbar action that downloads and installs the new APK
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateActionUpdate;

  /// Snackbar action that opens the release page for a non-APK platform
  ///
  /// In en, this message translates to:
  /// **'Get'**
  String get updateActionGet;

  /// Title of the update download progress dialog
  ///
  /// In en, this message translates to:
  /// **'Downloading v{version}'**
  String updateDownloading(String version);

  /// Error shown when the downloaded installer could not be launched
  ///
  /// In en, this message translates to:
  /// **'installer failed to open: {message}'**
  String updateInstallerFailed(String message);

  /// Title of the custom fields manager sheet
  ///
  /// In en, this message translates to:
  /// **'Custom fields'**
  String get customFieldsTitle;

  /// Inline-add label for a new custom field group
  ///
  /// In en, this message translates to:
  /// **'Add group'**
  String get customFieldsAddGroup;

  /// Inline-add label for a new custom field
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get customFieldsAddField;

  /// Menu item to rename a group or field
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get customFieldsMenuRename;

  /// Menu item to move a group or field up
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get customFieldsMenuMoveUp;

  /// Menu item to move a group or field down
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get customFieldsMenuMoveDown;

  /// Menu item to delete a group or field
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get customFieldsMenuDelete;

  /// Menu item to remove an instantiated group from the board
  ///
  /// In en, this message translates to:
  /// **'Remove from board'**
  String get customFieldsMenuRemoveFromBoard;

  /// Checked menu item and subtitle for the front-of-card toggle
  ///
  /// In en, this message translates to:
  /// **'Show on front of card'**
  String get customFieldsMenuShowOnFrontOfCard;

  /// Prefix for the popup-menu tooltip; followed by the group or field name
  ///
  /// In en, this message translates to:
  /// **'More actions for'**
  String get customFieldsMoreActions;

  /// Section header for board-level custom field groups
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get customFieldsBoardSection;

  /// Section header for card-level custom field groups
  ///
  /// In en, this message translates to:
  /// **'This card'**
  String get customFieldsCardSection;

  /// Empty state for the board section
  ///
  /// In en, this message translates to:
  /// **'No custom fields on this board yet. Fields you add here appear on every card.'**
  String get customFieldsBoardEmpty;

  /// Empty state for the card section
  ///
  /// In en, this message translates to:
  /// **'No fields on just this card. Fields you add here appear on this card only.'**
  String get customFieldsCardEmpty;

  /// Subtitle on an instantiated group row
  ///
  /// In en, this message translates to:
  /// **'From project template'**
  String get customFieldsFromTemplate;

  /// Caption under an instantiated group's read-only field list
  ///
  /// In en, this message translates to:
  /// **'Fields come from the template'**
  String get customFieldsTemplateFieldsReadOnly;

  /// Banner shown to board viewers at the top of the sheet
  ///
  /// In en, this message translates to:
  /// **'You have view-only access to this board.'**
  String get customFieldsViewerReadOnly;

  /// Snackbar shown when a viewer or guest gets a 403 trying to write a custom field
  ///
  /// In en, this message translates to:
  /// **'Only board editors can change custom fields.'**
  String get customFieldsEditorRequired;

  /// Title of the rename-group dialog
  ///
  /// In en, this message translates to:
  /// **'Rename group'**
  String get customFieldsRenameGroupTitle;

  /// Title of the rename-field dialog
  ///
  /// In en, this message translates to:
  /// **'Rename field'**
  String get customFieldsRenameFieldTitle;

  /// Title of the board-group delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete group?'**
  String get customFieldsGroupDeleteTitle;

  /// Body of the board-group delete confirmation
  ///
  /// In en, this message translates to:
  /// **'\"{name}\", its {fieldCount} fields, and every value stored under them on this board\'s cards are deleted. This cannot be undone.'**
  String customFieldsGroupDeleteMessage(String name, int fieldCount);

  /// Title of the card-group delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete group?'**
  String get customFieldsCardGroupDeleteTitle;

  /// Body of the card-group delete confirmation
  ///
  /// In en, this message translates to:
  /// **'\"{name}\", its {fieldCount} fields, and this card\'s values under them are deleted. This cannot be undone.'**
  String customFieldsCardGroupDeleteMessage(String name, int fieldCount);

  /// Title of the board-group field delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete field?'**
  String get customFieldsFieldInGroupDeleteTitle;

  /// Body of the board-group field delete confirmation
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" and its values on every card on this board are deleted. This cannot be undone.'**
  String customFieldsFieldInGroupDeleteMessage(String name);

  /// Title of the card-group field delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete field?'**
  String get customFieldsFieldInCardGroupDeleteTitle;

  /// Body of the card-group field delete confirmation
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" and its value on this card are deleted. This cannot be undone.'**
  String customFieldsFieldInCardGroupDeleteMessage(String name);

  /// Title of the template field delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete template field?'**
  String get customFieldsTemplateFieldDeleteTitle;

  /// Body of the template field delete confirmation. Names the scope (every board in this project) but never a number of boards — the projects payload does not carry board custom field groups, so any count would be invented.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is deleted from this template and from the copy of it on every board in this project that uses it, along with every value stored under it. This cannot be undone.'**
  String customFieldsTemplateFieldDeleteMessage(String name);

  /// Title of the remove-instantiated-group confirmation
  ///
  /// In en, this message translates to:
  /// **'Remove from board?'**
  String get customFieldsInstantiatedGroupRemoveTitle;

  /// Body of the remove-instantiated-group confirmation
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is removed from this board, and the values stored under it on this board\'s cards are deleted. The project template itself is kept. This cannot be undone.'**
  String customFieldsInstantiatedGroupRemoveMessage(String name);

  /// Accessibility announcement after a group or field is reordered
  ///
  /// In en, this message translates to:
  /// **'{name} moved to position {position} of {total}'**
  String customFieldsMovedToPosition(String name, int position, int total);

  /// Section header for the project's custom field templates on the sheet's first page
  ///
  /// In en, this message translates to:
  /// **'Project templates'**
  String get customFieldsTemplatesSection;

  /// Button at the end of the templates section that opens the templates page
  ///
  /// In en, this message translates to:
  /// **'Manage templates'**
  String get customFieldsManageTemplates;

  /// Tooltip of the back arrow on the templates page
  ///
  /// In en, this message translates to:
  /// **'Back to fields'**
  String get customFieldsBackToFields;

  /// Inline-add label for a new project field template
  ///
  /// In en, this message translates to:
  /// **'Add template'**
  String get customFieldsAddTemplate;

  /// Empty state for the templates page and section
  ///
  /// In en, this message translates to:
  /// **'This project has no field templates yet.'**
  String get customFieldsTemplatesEmpty;

  /// Error line shown in the templates section when the projects fetch fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load project templates'**
  String get customFieldsTemplatesLoadFailed;

  /// Subtitle on a template row giving how many fields it holds
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 field} other{{count} fields}}'**
  String customFieldsFieldCount(int count);

  /// Button that instantiates a template onto the current board
  ///
  /// In en, this message translates to:
  /// **'Add to board'**
  String get customFieldsAddToBoard;

  /// Trailing label replacing Add to board once the board already instantiates the template
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get customFieldsAddedToBoard;

  /// Title of the template delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete template?'**
  String get customFieldsTemplateDeleteTitle;

  /// Body of the template delete confirmation. Names the scope (every board in this project) but never a number of boards — the projects payload does not carry board custom field groups, so any count would be invented.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\", its {fieldCount, plural, =1{1 field} other{{fieldCount} fields}}, and the copy of this group on every board in this project that uses it are deleted, along with every value stored under them. This cannot be undone.'**
  String customFieldsTemplateDeleteMessage(String name, int fieldCount);

  /// Snackbar shown when the server refuses a template write; the server answers a non-manager with projectNotFound, so the raw message would read as a missing project
  ///
  /// In en, this message translates to:
  /// **'Only project managers can change field templates.'**
  String get customFieldsManagersRequired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
