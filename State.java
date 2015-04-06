// Processing CAN use enums, if they're in a Java file!
public enum State {
  PAUSED,  // user paused
  RUNNING, // in a wave
  STAGED,  // between waves
  MENU,    // user in menu
  UPGRADE, // user in upgrade menu
}
