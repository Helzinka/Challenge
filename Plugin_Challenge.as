#name       "Challenge !"
#author     "Helzinka"
#category   "Utilities"
#version    "1.1"

#include    "Icons.as"
#include    "Time.as"

// Thanks to skybaxrider and Miss for pb value

[Setting name="Show Challenge"]
bool Show_widget = true;

[Setting name="Position X"]
int Position_x = 20;

[Setting name="Position Y"]
int Position_y = 790;

[Setting name="Width"]
int Width = 280;

[Setting name="Height"]
int Height = 180;

bool is_ingame = false;
bool is_respawn = true;
bool get_pb = true;
bool get_pb_once = false;

string author_nickname;
int nb_respawns = -1;
int game_time;
uint curr_cp = 0;
int goal_time = 0;
int author_time = 0;
int personal_best = 0;

void RenderMenu() {
  if (UI::MenuItem("\\$9fc" + Icons::Check + "\\$z Challenge !", "",  Show_widget)) {
      Show_widget = !Show_widget;
  }
}

void Render() {
  string game_t = Time::Format(game_time, false);

  if (is_ingame && Show_widget) {
    UI::SetNextWindowSize(Width, Height);
    UI::SetNextWindowPos(Position_x, Position_y);
    UI::Begin(Color_succes(), Show_widget);
    if(goal_time > 0 ) {
      UI::Text("Goal time : " + Time::Format(goal_time));
    } else if (author_time < 0) {
      UI::Text("Goal time : AT not set yet");
    }else {
      UI::Text("Goal time : " + Time::Format(author_time) + ' (AT)');
    }
    goal_time = UI::InputInt("(ms)", goal_time , 1);
    if(goal_time >= 1 || goal_time <= -1) {
      UI::SameLine();
      auto reset_goal_time = UI::Button("\\$fff" + Icons::Redo);
      if(reset_goal_time) {
        goal_time =0;
      }
    }
    UI::Separator();
    if( personal_best <= 0) {
      UI::Text("Personal best : not set yet");
    } else {
      UI::Text("Personal best : " + Time::Format(personal_best));
    }
    UI::Separator();
    UI::Text("Game time : " + game_t);
    UI::Separator();
    UI::Text("Respawns counter : " + nb_respawns);
    UI::SameLine();
    if (nb_respawns >= 1) {
      auto reset_respawn = UI::Button("\\$fff" + Icons::Redo);
      if(reset_respawn) {
        nb_respawns =0;
      }
    }
    UI::End();
  } 
}
string Color_succes() {
  if (personal_best <= 0) {
      return "\\$ec5" + Icons::Search + "\\$z Challenged by \\$ec5" + author_nickname;
  }else if (goal_time > 0 ) {
    if (personal_best < goal_time) {
      return "\\$7e5" + Icons::Check + "\\$z Challenged by \\$7e5" + author_nickname;
    } else {
      return "\\$e55" + Icons::Times + "\\$z Challenged by \\$e55" + author_nickname;
    }
  } else if (personal_best < author_time) {
    return "\\$7e5" + Icons::Check + "\\$z Challenged by \\$7e5" + author_nickname;
  } else {
    return "\\$e55" + Icons::Times + "\\$z Challenged by \\$e55" + author_nickname;
  }
}

void Get_respawn(int nb_res) {
  if(nb_res == 0){
    if (is_respawn != false){
      nb_respawns++;
      is_respawn = false;
    }
  } else {
    is_respawn = true;
  }
}

void Update(float dt) {

  CSmArenaClient@ playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
  if(playground !is null) {
    if(playground.GameTerminals.Length <= 0
       || cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer) is null
       || playground.Arena is null
       || playground.Map is null) {
      is_ingame = false;
      return;
    }
    is_ingame = true;
    if(playground.GameTerminals.Length > 0 && is_ingame) {

      CSmPlayer@ player = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
      CGameCtnChallenge@ map = GetApp().RootMap;
      CTrackManiaNetwork@ net = cast<CTrackManiaNetwork>(GetApp().Network);
      CSmScriptPlayer@ scriptApi = cast<CSmScriptPlayer>(player.ScriptAPI);

      curr_cp = player.CurrentLaunchedRespawnLandmarkIndex;
      game_time = net.PlaygroundClientScriptAPI.GameTime;
      author_nickname = map.MapInfo.AuthorNickName;
      author_time = map.MapInfo.TMObjective_AuthorTime;

      if(player !is null) {
        if(scriptApi !is null) {
          Get_respawn(scriptApi.Post);
          if(get_pb){
            personal_best = GetApp().PlaygroundScript.ScoreMgr.Map_GetRecord_v2(net.PlayerInfo.Id, map.MapInfo.MapUid, "PersonalBest", "", "TimeAttack", "");
            get_pb = false;
          }
          if(playground.GameTerminals[0].UISequence_Current == ESGamePlaygroundUIConfig__EUISequence::Finish) {
            if (get_pb_once) {
              personal_best = GetApp().PlaygroundScript.ScoreMgr.Map_GetRecord_v2(net.PlayerInfo.Id, map.MapInfo.MapUid, "PersonalBest", "", "TimeAttack", "");
            }
            get_pb_once = false;
          }else {
            get_pb_once = true;
          }
        }
      }
    }
  } else {
    is_ingame = false;
    nb_respawns = -1;
    get_pb = true;
  }
}
