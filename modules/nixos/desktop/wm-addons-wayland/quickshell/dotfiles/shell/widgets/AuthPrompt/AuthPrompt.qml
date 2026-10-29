import Quickshell
import qs.services

Scope {
  id: root

  LazyLoader {
    // stays loaded while the exit animation runs
    active: SAuth.isLoaded
    component: AuthPromptContent {}
  }
}
