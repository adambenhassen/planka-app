// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Planka';

  @override
  String get actionAccept => 'Accept';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionMove => 'Move';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionRestore => 'Restore';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionSave => 'Save';

  @override
  String get actionUpload => 'Upload';

  @override
  String get fieldBoard => 'Board';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldList => 'List';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldProject => 'Project';

  @override
  String get fieldRequired => 'Required';

  @override
  String get valueNotSet => '—';

  @override
  String get unknownUser => 'Unknown';

  @override
  String get errorInvalidCredentials => 'Invalid credentials';

  @override
  String get loginSubtitle => 'Sign in to your server';

  @override
  String get loginServerUrl => 'Server URL';

  @override
  String get loginEmailOrUsername => 'Email or username';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginSubmit => 'Log in';

  @override
  String get loginSessionExpired => 'Session expired — log in again';

  @override
  String get loginTermsTitle => 'Accept Terms of Service?';

  @override
  String get loginTermsMessage =>
      'This server requires you to accept its Terms of Service to log in.';

  @override
  String get loginTotpTitle => 'Two-factor authentication';

  @override
  String get loginTotpSubtitle =>
      'Enter the code from your authenticator app, or one of your recovery codes.';

  @override
  String get loginTotpCode => 'Authentication code';

  @override
  String get loginTotpVerify => 'Verify';

  @override
  String get loginTotpRejected => 'That code was rejected. Try again.';

  @override
  String get loginTotpExpired =>
      'Sign-in timed out. Enter your password again.';

  @override
  String get projectsTitle => 'Projects';

  @override
  String get projectsEmpty => 'No projects yet';

  @override
  String get projectNewTooltip => 'New project';

  @override
  String get projectNewTitle => 'New project';

  @override
  String get projectNameHint => 'Project name';

  @override
  String get projectRenameTitle => 'Rename project';

  @override
  String get projectDeleteTitle => 'Delete project?';

  @override
  String get projectDeleteMessage =>
      'The project and all its boards will be permanently deleted.';

  @override
  String get projectMenuAddBoard => 'Add board';

  @override
  String get projectMenuManagers => 'Managers';

  @override
  String get projectMenuCustomFields => 'Custom fields';

  @override
  String get projectMenuBackground => 'Background';

  @override
  String get boardNewTitle => 'New board';

  @override
  String get boardNameHint => 'Board name';

  @override
  String get boardFallbackTitle => 'Board';

  @override
  String get boardFilterTooltip => 'Filter cards';

  @override
  String get boardSearchHint => 'Search cards…';

  @override
  String get boardMenuRename => 'Rename board';

  @override
  String get boardMenuDelete => 'Delete board';

  @override
  String get boardRenameTitle => 'Rename board';

  @override
  String get boardDeleteTitle => 'Delete board?';

  @override
  String get boardDeleteMessage =>
      'The board and everything on it will be deleted.';

  @override
  String get boardReconnecting => 'Reconnecting…';

  @override
  String get listAdd => 'Add list';

  @override
  String get listNameHint => 'List name';

  @override
  String get listRenameTitle => 'Rename list';

  @override
  String get listDeleteTitle => 'Delete list?';

  @override
  String get listDeleteMessage => 'The list and all its cards will be deleted.';

  @override
  String get listMenuSort => 'Sort by…';

  @override
  String get listSortTitle => 'Sort by';

  @override
  String listSortOption(String field, String order) {
    return '$field ($order)';
  }

  @override
  String get listSortFieldDueDate => 'Due date';

  @override
  String get listSortFieldCreatedDate => 'Created date';

  @override
  String get listSortOrderAscending => 'ascending';

  @override
  String get listSortOrderDescending => 'descending';

  @override
  String get cardAdd => 'Add card';

  @override
  String get cardNameHint => 'Card name';

  @override
  String get cardGone => 'Card no longer exists';

  @override
  String get cardWatch => 'Watch card';

  @override
  String get cardUnwatch => 'Unwatch card';

  @override
  String get cardDuplicate => 'Duplicate card';

  @override
  String get cardMove => 'Move…';

  @override
  String get cardArchive => 'Archive card';

  @override
  String get cardMoveToTrash => 'Move to trash';

  @override
  String get cardDelete => 'Delete card';

  @override
  String get cardDeleteTitle => 'Delete card?';

  @override
  String get cardDeleteMessage => 'This card will be permanently deleted.';

  @override
  String get cardDescriptionHint => 'Add a description…';

  @override
  String cardOpenAttachmentFailed(String name, String message) {
    return 'Could not open $name: $message';
  }

  @override
  String get moveCardTitle => 'Move card';

  @override
  String get sectionStopwatch => 'Stopwatch';

  @override
  String get sectionLabels => 'Labels';

  @override
  String get sectionMembers => 'Members';

  @override
  String get sectionChecklists => 'Checklists';

  @override
  String get sectionAttachments => 'Attachments';

  @override
  String get sectionComments => 'Comments';

  @override
  String get sectionActivity => 'Activity';

  @override
  String get dueDateSet => 'Set due date';

  @override
  String get dueDateRemove => 'Remove due date';

  @override
  String get stopwatchStart => 'Start stopwatch';

  @override
  String get stopwatchPause => 'Pause';

  @override
  String get stopwatchResume => 'Resume';

  @override
  String get stopwatchReset => 'Reset stopwatch';

  @override
  String get labelChip => 'Label';

  @override
  String get labelNewName => 'New label name';

  @override
  String get labelRenameTitle => 'Rename label';

  @override
  String get labelDeleteTitle => 'Delete label?';

  @override
  String get labelDeleteMessage =>
      'The label is removed from the board and all cards.';

  @override
  String get checklistAdd => 'Add checklist';

  @override
  String get checklistRenameTitle => 'Rename checklist';

  @override
  String get checklistDeleteTitle => 'Delete checklist?';

  @override
  String get checklistDeleteMessage =>
      'The checklist and its tasks will be deleted.';

  @override
  String get taskAdd => 'Add task';

  @override
  String get taskRenameTitle => 'Rename task';

  @override
  String get taskDeleteTitle => 'Delete task?';

  @override
  String get attachmentAdd => 'Add attachment';

  @override
  String get attachmentCover => 'Cover';

  @override
  String get attachmentSetAsCover => 'Set as cover';

  @override
  String get attachmentRemoveCover => 'Remove cover';

  @override
  String get commentHint => 'Write a comment…';

  @override
  String get commentSend => 'Send';

  @override
  String get commentEditTitle => 'Edit comment';

  @override
  String get commentDeleteTitle => 'Delete comment?';

  @override
  String get activityLoadError => 'Could not load activity';

  @override
  String get activityEmpty => 'No activity yet';

  @override
  String activityEntry(String user, String description) {
    return '$user $description';
  }

  @override
  String get activitySomeone => 'Someone';

  @override
  String get activityAMember => 'a member';

  @override
  String get activityATask => 'a task';

  @override
  String get activityCreatedCard => 'created this card';

  @override
  String activityCreatedCardInList(String list) {
    return 'created this card in $list';
  }

  @override
  String get activityMovedCard => 'moved this card';

  @override
  String activityMovedCardFromTo(String from, String to) {
    return 'moved this card from $from to $to';
  }

  @override
  String activityAddedMember(String member) {
    return 'added $member to this card';
  }

  @override
  String activityRemovedMember(String member) {
    return 'removed $member from this card';
  }

  @override
  String activityCompletedTask(String task) {
    return 'completed $task';
  }

  @override
  String activityUncompletedTask(String task) {
    return 'uncompleted $task';
  }

  @override
  String get activityUpdatedCard => 'updated this card';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get boardMembersTitle => 'Board members';

  @override
  String get boardMemberAdd => 'Add member';

  @override
  String get boardMemberRemoveTitle => 'Remove member?';

  @override
  String get boardMemberRemoveMessage => 'They will lose access to this board.';

  @override
  String get boardMemberMakeEditor => 'Make editor';

  @override
  String get boardMemberMakeViewer => 'Make viewer';

  @override
  String get boardMembersAdminRequired =>
      'Adding members requires admin rights';

  @override
  String get boardMembersAllAdded => 'Everyone is already a member';

  @override
  String get boardRoleEditor => 'editor';

  @override
  String get boardRoleViewer => 'viewer';

  @override
  String get projectManagersTitle => 'Project managers';

  @override
  String get projectManagerAdd => 'Add manager';

  @override
  String get projectManagerRemoveTooltip => 'Remove manager';

  @override
  String get projectManagerRemoveTitle => 'Remove manager?';

  @override
  String get projectManagerRemoveMessage =>
      'They will lose manager access to this project.';

  @override
  String get projectManagersAdminRequired =>
      'Adding managers requires admin rights';

  @override
  String get projectManagersAllAdded => 'Everyone is already a manager';

  @override
  String get projectBackgroundTitle => 'Project background';

  @override
  String get projectBackgroundUploadImage => 'Upload image';

  @override
  String get projectBackgroundNone => 'None';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileOrganization => 'Organization';

  @override
  String get profileUsername => 'Username';

  @override
  String get profileChangeEmail => 'Change email';

  @override
  String get profileNewEmail => 'New email';

  @override
  String get profileChangeUsername => 'Change username';

  @override
  String get profileNewUsername => 'New username';

  @override
  String get profileChangePassword => 'Change password';

  @override
  String get profileNewPassword => 'New password';

  @override
  String get profileCurrentPassword => 'Current password';

  @override
  String get manageUsersTitle => 'Manage users';

  @override
  String get userAdd => 'Add user';

  @override
  String get userDeleteTitle => 'Delete user?';

  @override
  String userDeleteMessage(String name) {
    return '$name will be permanently removed.';
  }

  @override
  String userMakeRole(String role) {
    return 'Make $role';
  }

  @override
  String get userDeactivate => 'Deactivate';

  @override
  String get userReactivate => 'Reactivate';

  @override
  String get userRoleAdmin => 'admin';

  @override
  String get userRoleProjectOwner => 'projectOwner';

  @override
  String get userRoleBoardUser => 'boardUser';

  @override
  String get accountAdd => 'Add account';

  @override
  String get archiveTrashTitle => 'Archive & trash';

  @override
  String get archiveTab => 'Archive';

  @override
  String get trashTab => 'Trash';

  @override
  String get archiveTrashNoList => 'No list on this board';

  @override
  String get archiveTrashEmpty => 'Nothing here';

  @override
  String updateAvailable(String version) {
    return 'Update available (v$version)';
  }

  @override
  String get updateActionUpdate => 'Update';

  @override
  String get updateActionGet => 'Get';

  @override
  String updateDownloading(String version) {
    return 'Downloading v$version';
  }

  @override
  String updateInstallerFailed(String message) {
    return 'installer failed to open: $message';
  }

  @override
  String get customFieldsTitle => 'Custom fields';

  @override
  String get customFieldsAddGroup => 'Add group';

  @override
  String get customFieldsAddField => 'Add field';

  @override
  String get customFieldsMenuRename => 'Rename';

  @override
  String get customFieldsMenuMoveUp => 'Move up';

  @override
  String get customFieldsMenuMoveDown => 'Move down';

  @override
  String get customFieldsMenuDelete => 'Delete';

  @override
  String get customFieldsMenuRemoveFromBoard => 'Remove from board';

  @override
  String get customFieldsMenuShowOnFrontOfCard => 'Show on front of card';

  @override
  String get customFieldsMoreActions => 'More actions for';

  @override
  String get customFieldsBoardSection => 'Board';

  @override
  String get customFieldsCardSection => 'This card';

  @override
  String get customFieldsBoardEmpty =>
      'No custom fields on this board yet. Fields you add here appear on every card.';

  @override
  String get customFieldsCardEmpty =>
      'No fields on just this card. Fields you add here appear on this card only.';

  @override
  String get customFieldsFromTemplate => 'From project template';

  @override
  String get customFieldsTemplateFieldsReadOnly =>
      'Fields come from the template';

  @override
  String get customFieldsViewerReadOnly =>
      'You have view-only access to this board.';

  @override
  String get customFieldsEditorRequired =>
      'Only board editors can change custom fields.';

  @override
  String get customFieldsRenameGroupTitle => 'Rename group';

  @override
  String get customFieldsRenameFieldTitle => 'Rename field';

  @override
  String get customFieldsGroupDeleteTitle => 'Delete group?';

  @override
  String customFieldsGroupDeleteMessage(String name, int fieldCount) {
    return '\"$name\", its $fieldCount fields, and every value stored under them on this board\'s cards are deleted. This cannot be undone.';
  }

  @override
  String get customFieldsCardGroupDeleteTitle => 'Delete group?';

  @override
  String customFieldsCardGroupDeleteMessage(String name, int fieldCount) {
    return '\"$name\", its $fieldCount fields, and this card\'s values under them are deleted. This cannot be undone.';
  }

  @override
  String get customFieldsFieldInGroupDeleteTitle => 'Delete field?';

  @override
  String customFieldsFieldInGroupDeleteMessage(String name) {
    return '\"$name\" and its values on every card on this board are deleted. This cannot be undone.';
  }

  @override
  String get customFieldsFieldInCardGroupDeleteTitle => 'Delete field?';

  @override
  String customFieldsFieldInCardGroupDeleteMessage(String name) {
    return '\"$name\" and its value on this card are deleted. This cannot be undone.';
  }

  @override
  String get customFieldsInstantiatedGroupRemoveTitle => 'Remove from board?';

  @override
  String customFieldsInstantiatedGroupRemoveMessage(String name) {
    return '\"$name\" is removed from this board, and the values stored under it on this board\'s cards are deleted. The project template itself is kept. This cannot be undone.';
  }

  @override
  String customFieldsMovedToPosition(String name, int position, int total) {
    return '$name moved to position $position of $total';
  }

  @override
  String get customFieldsTemplatesSection => 'Project templates';

  @override
  String get customFieldsManageTemplates => 'Manage templates';

  @override
  String get customFieldsBackToFields => 'Back to fields';

  @override
  String get customFieldsAddTemplate => 'Add template';

  @override
  String get customFieldsTemplatesEmpty =>
      'This project has no field templates yet.';

  @override
  String get customFieldsTemplatesLoadFailed =>
      'Couldn\'t load project templates';

  @override
  String customFieldsFieldCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fields',
      one: '1 field',
    );
    return '$_temp0';
  }

  @override
  String get customFieldsAddToBoard => 'Add to board';

  @override
  String get customFieldsAddedToBoard => 'Added';

  @override
  String get customFieldsTemplateDeleteTitle => 'Delete template?';

  @override
  String customFieldsTemplateDeleteMessage(String name, int fieldCount) {
    return '\"$name\", its $fieldCount fields, and the copy of this group on every board in this project that uses it are deleted, along with every value stored under them. This cannot be undone.';
  }

  @override
  String get customFieldsManagersRequired =>
      'Only project managers can change field templates.';
}
