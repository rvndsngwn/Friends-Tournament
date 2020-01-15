/*
 * Copyright 2019 Marco Gomiero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:core';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:friends_tournament/src/data/database/dao/match_dao.dart';
import 'package:friends_tournament/src/data/database/dao/match_session_dao.dart';
import 'package:friends_tournament/src/data/database/dao/player_dao.dart';
import 'package:friends_tournament/src/data/database/dao/player_session_dao.dart';
import 'package:friends_tournament/src/data/database/dao/session_dao.dart';
import 'package:friends_tournament/src/data/database/dao/tournament_dao.dart';
import 'package:friends_tournament/src/data/database/dao/tournament_match_dao.dart';
import 'package:friends_tournament/src/data/database/dao/tournament_player_dao.dart';
import 'package:friends_tournament/src/data/database/database_provider.dart';
import 'package:friends_tournament/src/data/database/db_data_source.dart';
import 'package:friends_tournament/src/data/model/db/match.dart';
import 'package:friends_tournament/src/data/model/db/match_session.dart';
import 'package:friends_tournament/src/data/model/db/player.dart';
import 'package:friends_tournament/src/data/model/db/player_session.dart';
import 'package:friends_tournament/src/data/model/db/session.dart';
import 'package:friends_tournament/src/data/model/db/tournament.dart';
import 'package:friends_tournament/src/data/model/db/tournament_match.dart';
import 'package:friends_tournament/src/data/model/db/tournament_player.dart';
import 'package:friends_tournament/src/utils/id_generator.dart';

class SetupRepository {
  // Implement singleton
  // To get back it, simple call: MyClass myObj = new MyClass();
  /// -------
  static final SetupRepository _singleton = new SetupRepository._internal();

  factory SetupRepository() {
    return _singleton;
  }

  SetupRepository._internal();

  /// -------

  final _random = new Random();

  /* *************
  *
  * Internal Variables
  *
  * ************** */
  @visibleForTesting
  List<Player> players = List<Player>();
  @visibleForTesting
  List<Session> sessions = List<Session>();
  @visibleForTesting
  List<Match> matches = List<Match>();
  @visibleForTesting
  List<PlayerSession> playerSessionList = List<PlayerSession>();
  @visibleForTesting
  List<MatchSession> matchSessionList = List<MatchSession>();
  List<TournamentMatch> _tournamentMatchList = List<TournamentMatch>();
  List<TournamentPlayer> _tournamentPlayerList = List<TournamentPlayer>();

  Tournament _tournament;

  int _playersNumber;
  int _playersAstNumber;
  int _matchesNumber;
  String _tournamentName;

  DatabaseProvider databaseProvider = DatabaseProvider.get;
  var setupDataSource = DBDataSource();

  Future setupTournament(
      int playersNumber,
      int playersAstNumber,
      int matchesNumber,
      String tournamentName,
      Map<int, String> playersName,
      Map<int, String> matchesName) async {
    createTournament(playersNumber, playersAstNumber, matchesNumber,
        tournamentName, playersName, matchesName);
    await _save();
  }

  void createTournament(
      int playersNumber,
      int playersAstNumber,
      int matchesNumber,
      String tournamentName,
      Map<int, String> playersName,
      Map<int, String> matchesName) {


    // TODO: maybe add a sanity check with sizes

    this._playersNumber = playersNumber;
    this._playersAstNumber = playersAstNumber;
    this._matchesNumber = matchesNumber;
    this._tournamentName = tournamentName;

    this._tournament = Tournament(generateTournamentId(_tournamentName),
        _tournamentName, _playersNumber, _playersAstNumber, _matchesNumber, 1);

    _setupPlayers(playersName);
    _setupMatches(matchesName);
    _generateTournament();
  }

  void _setupPlayers(Map<int, String> playersName) {
    playersName.forEach((_, playerName) {
      var playerId = generatePlayerId(playerName);
      var player = Player(playerId, playerName);
      players.add(player);
      var tournamentPlayer = TournamentPlayer(playerId, _tournament.id, 0);
      _tournamentPlayerList.add(tournamentPlayer);
    });
  }

  void _setupMatches(Map<int, String> matchesName) {
    matchesName.forEach((index, matchName) {
      var matchId = generateMatchId(_tournamentName, matchName);
      var isActiveMatch = 0;
      if (index == 0) {
        isActiveMatch = 1;
      }
      var match = Match(matchId, matchName, isActiveMatch, index);
      if (matches.contains(match)) {
        throw Exception("Two matches has the same name");
      } else {
        matches.add(match);
        var tournamentMatch = TournamentMatch(_tournament.id, matchId);
        _tournamentMatchList.add(tournamentMatch);
      }
    });
  }

  void _generateTournament() {
    matches.forEach((match) {
      // number of sessions for the same match
      int sessionsNumber = (_matchesNumber / _playersAstNumber).ceil();
      var currentSessionPlayers = List<String>();
      for (int i = 0; i < sessionsNumber; i++) {
        // TODO: localize
        var sessionName = "Session ${i + 1}";
        var sessionId = generateSessionId(match.id, sessionName);
        var session = Session(sessionId, sessionName, i);
        sessions.add(session);
        var matchSession = MatchSession(match.id, sessionId);
        matchSessionList.add(matchSession);
        for (int j = 0; j < _playersAstNumber; j++) {
          while (true) {
            int playerIndex = _random.nextInt(_playersNumber);
            final playerCandidate = players[playerIndex];
            if (currentSessionPlayers.contains(playerCandidate.id)) {
              continue;
            } else {
              currentSessionPlayers.add(playerCandidate.id);
              var playerSession =
                  PlayerSession(playerCandidate.id, sessionId, 0);
              playerSessionList.add(playerSession);
              break;
            }
          }
        }
      }
    });
  }

  Future _save() async {
    print("Launching the save process");

    await setupDataSource.createBatch();

    // TODO: add first a check to control if there is a current tournament active. Just for control

    // save tournament
    setupDataSource.insertToBatch(_tournament, TournamentDao());
    print(_tournament.toString());

    // save players
    var playerDao = PlayerDao();
    players.forEach((player) {
      setupDataSource.insertIgnoreToBatch(player, playerDao);
      print(player.toString());
    });

    // save sessions
    var sessionDao = SessionDao();
    sessions.forEach((session) {
      setupDataSource.insertToBatch(session, sessionDao);
      print(session.toString());
    });

    // save matches
    var matchDao = MatchDao();
    matches.forEach((match) {
      setupDataSource.insertToBatch(match, matchDao);
      print(match.toString());
    });

    // save tournament player
    var tournamentPlayerDao = TournamentPlayerDao();
    _tournamentPlayerList.forEach((tournamentPlayer) {
      setupDataSource.insertToBatch(tournamentPlayer, tournamentPlayerDao);
      print(tournamentPlayer.toString());
    });

    // save player session
    var playerSessionDao = PlayerSessionDao();
    playerSessionList.forEach((playerSession) {
      setupDataSource.insertToBatch(playerSession, playerSessionDao);
      print(playerSession.toString());
    });

    // save match session
    var matchSessionDao = MatchSessionDao();
    matchSessionList.forEach((matchSession) {
      setupDataSource.insertToBatch(matchSession, matchSessionDao);
      print(matchSession.toString());
    });

    // save tournament match
    var tournamentMatchDao = TournamentMatchDao();
    _tournamentMatchList.forEach((tournamentMatch) {
      print(tournamentMatch.toString());
      setupDataSource.insertToBatch(tournamentMatch, tournamentMatchDao);
    });

    await setupDataSource.flushBatch();
  }
}
