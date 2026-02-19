/// Centralized string constants for RIVL.
/// Keeps UI text in one place for consistency and future i18n support.
class AppStrings {
  AppStrings._(); // prevent instantiation

  // ── App ──────────────────────────────────────────────────────────────
  static const appName = 'RIVL';
  static const appTagline = 'Compete. Win. Earn.';
  static const appDescription = 'AI-Powered Fitness Competition';

  // ── Auth ─────────────────────────────────────────────────────────────
  static const login = 'Log In';
  static const signIn = 'Sign In';
  static const signUp = 'Sign Up';
  static const logout = 'Log Out';
  static const signOut = 'Sign Out';
  static const email = 'Email';
  static const password = 'Password';
  static const confirmPassword = 'Confirm Password';
  static const username = 'Username';
  static const displayName = 'Display Name';
  static const fullName = 'Full Name';
  static const forgotPassword = 'Forgot Password?';
  static const resetPassword = 'Reset Password';
  static const orContinueWith = 'or continue with';
  static const signInWithApple = 'Sign in with Apple';
  static const signInWithGoogle = 'Sign in with Google';
  static const dontHaveAccount = "Don't have an account? ";
  static const alreadyHaveAccount = 'Already have an account? ';
  static const createAccount = 'Create Account';
  static const welcomeBack = 'Welcome Back';
  static const signInToContinue = 'Sign in to continue competing';
  static const joinRivl = 'Join RIVL';
  static const startCompeting = 'Start competing with friends today';
  static const rememberMe = 'Remember me';
  static const termsAgreement =
      'By signing up, you agree to our Terms of Service and Privacy Policy';
  static const referralCodeOptional = 'Referral Code (optional)';

  // ── Auth Validation ──────────────────────────────────────────────────
  static const enterEmail = 'Please enter your email';
  static const enterValidEmail = 'Please enter a valid email';
  static const enterPassword = 'Please enter your password';
  static const enterName = 'Please enter your name';
  static const enterUsername = 'Please enter a username';
  static const passwordMinLength = 'Password must be at least 6 characters';
  static const passwordMinLength8 = 'Password must be at least 8 characters';
  static const usernameMinLength = 'Username must be at least 3 characters';
  static const usernameCharsOnly =
      'Only letters, numbers, and underscores allowed';
  static const passwordsDoNotMatch = 'Passwords do not match';

  // ── Navigation ───────────────────────────────────────────────────────
  static const home = 'Home';
  static const challenges = 'Challenges';
  static const create = 'Create';
  static const hub = 'Hub';
  static const feed = 'Feed';
  static const profile = 'Profile';

  // ── Challenges ───────────────────────────────────────────────────────
  static const active = 'Active';
  static const activeChallenges = 'Active Challenges';
  static const pending = 'Pending';
  static const pendingChallenges = 'Pending';
  static const completed = 'Completed';
  static const completedChallenges = 'Completed';
  static const challengeHistory = 'History';
  static const noChallenges = 'No challenges yet';
  static const noActiveChallenges = 'No active challenges';
  static const noPendingInvites = 'No pending invites';
  static const noHistoryYet = 'No history yet';
  static const createChallenge = 'Create Challenge';
  static const createNewChallenge = 'Create new challenge';
  static const sendChallenge = 'Send Challenge';
  static const challengeSent = 'Challenge Sent!';
  static const acceptChallenge = 'Accept';
  static const declineChallenge = 'Decline';
  static const challengeAccepted = 'Challenge accepted! Good luck!';
  static const challengeDeclined = 'Challenge declined';
  static const failedToAccept = 'Failed to accept challenge';
  static const failedToDecline = 'Failed to decline challenge';
  static const actionRequired = 'Action Required';

  // ── Challenge Types ──────────────────────────────────────────────────
  static const headToHead = '1v1 Challenge';
  static const groupLeague = 'Group League';
  static const squadVsSquad = 'Squad vs Squad';
  static const charityChallenge = '1v1 for Charity';

  // ── Health ───────────────────────────────────────────────────────────
  static const todaysActivity = "Today's Activity";
  static const healthCategories = 'Health Categories';
  static const steps = 'Steps';
  static const heartRate = 'Heart Rate';
  static const sleep = 'Sleep';
  static const distance = 'Distance';
  static const calories = 'Calories';
  static const rivlHealthScore = 'RIVL Health Score';
  static const showingDemoData = 'Showing demo health data';
  static const tapToConnect = 'Tap to connect';
  static const demoDataNotice =
      'Showing sample data. Connect Apple Health or Google Fit for real metrics.';
  static const connectHealth = 'Connect';
  static const healthAppConnection = 'Health App Connection';

  // ── Wallet ───────────────────────────────────────────────────────────
  static const wallet = 'Wallet';
  static const walletBalance = 'Wallet Balance';
  static const availableBalance = 'Available Balance';
  static const balance = 'Balance';
  static const atStake = 'At Stake';
  static const deposit = 'Deposit';
  static const depositFunds = 'Deposit Funds';
  static const addFunds = 'Add Funds';
  static const withdraw = 'Withdraw';
  static const withdrawFunds = 'Withdraw Funds';
  static const transactions = 'Transactions';
  static const transactionHistory = 'Transaction History';
  static const recentActivity = 'Recent Activity';
  static const noTransactions = 'No transactions yet';
  static const depositToStart = 'Deposit funds to get started';
  static const viewAllTransactions = 'View All Transactions';
  static const lifetimeStats = 'Lifetime Stats';
  static const winnings = 'Winnings';
  static const losses = 'Losses';
  static const netProfit = 'Net Profit';
  static const minimumDeposit = 'Minimum deposit is \$10';
  static const minimumWithdrawal = 'Minimum withdrawal is \$10';
  static const bankLinkingComingSoon = 'Bank linking coming soon!';

  // ── Profile ──────────────────────────────────────────────────────────
  static const settings = 'Settings';
  static const editProfile = 'Edit Profile';
  static const editAttributes = 'Edit Attributes';
  static const changePassword = 'Change Password';
  static const privacyPolicy = 'Privacy Policy';
  static const termsOfService = 'Terms of Service';
  static const achievements = 'Achievements';
  static const attributes = 'Attributes';
  static const performance = 'Performance';
  static const referFriends = 'Refer Friends';
  static const referralEarnMessage = 'Earn \$2 for each friend who joins!';
  static const codeCopied = 'Code copied!';
  static const friends = 'Friends';
  static const helpAndSupport = 'Help & Support';
  static const demoModeBanner = 'Demo Mode — Sign in to see your real stats';
  static const verified = 'Verified';
  static const premium = 'Premium';

  // ── General ──────────────────────────────────────────────────────────
  static const loading = 'Loading...';
  static const retry = 'Retry';
  static const cancel = 'Cancel';
  static const confirm = 'Confirm';
  static const save = 'Save';
  static const delete = 'Delete';
  static const done = 'Done';
  static const next = 'Continue';
  static const back = 'Back';
  static const close = 'Close';
  static const seeAll = 'See All';
  static const search = 'Search';
  static const noResults = 'No results found';
  static const somethingWentWrong = 'Something went wrong';
  static const tryAgain = 'Please try again';
  static const noInternet = 'No internet connection';
  static const gotIt = 'Got it';
  static const edit = 'Edit';
  static const link = 'Link';

  // ── Notifications ────────────────────────────────────────────────────
  static const notifications = 'Notifications';
  static const noNotifications = 'No notifications yet';
  static const markAllRead = 'Mark all read';

  // ── Errors ───────────────────────────────────────────────────────────
  static const errorGeneric = 'Something went wrong. Please try again.';
  static const errorNetwork = 'Network error. Check your connection.';
  static const errorAuth = 'Authentication failed. Please try again.';
  static const errorInsufficientFunds =
      'Insufficient funds. Please add money to your wallet.';

  // ── Theme ────────────────────────────────────────────────────────────
  static const themeLight = 'Light';
  static const themeDark = 'Dark';
  static const themeDevice = 'Device';
  static const changeTheme = 'Change theme';
  static const aboutRivl = 'About RIVL';
  static const whatIsRivl = 'What is RIVL?';
}
