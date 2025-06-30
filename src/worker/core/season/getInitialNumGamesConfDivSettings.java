import java.util.List;
import java.util.Map;

public class Schedule {

    public static final int TOO_MANY_TEAMS_TOO_SLOW = 150;

    public static Map<String, Object> getInitialNumGamesConfDivSettings(List<Team> teams, NewScheduleGoodSettings settingsInput) {
        NewScheduleGoodSettings settings = new NewScheduleGoodSettings(settingsInput);

        List<ScheduleTeam> scheduleTeams = teams.stream()
                .map(team -> new ScheduleTeam(team.getTid(), new SeasonAttributes(team.getDid(), team.getCid())))
                .toList();

        if (settings.getNumGamesDiv() != null && settings.getNumGamesConf() != null && teams.size() < TOO_MANY_TEAMS_TOO_SLOW) {
            Map<String, Object> result = NewScheduleGood.schedule(scheduleTeams, settings);
            if (result.get("warning") != null) {
                return Map.of(
                        "altered", true,
                        "numGamesDiv", null,
                        "numGamesConf", null
                );
            }
        }

        return Map.of(
                "numGamesDiv", settings.getNumGamesDiv(),
                "numGamesConf", settings.getNumGamesConf()
        );
    }

    private static class Team {
        private final int tid;
        private final int cid;
        private final int did;

        public Team(int tid, int cid, int did) {
            this.tid = tid;
            this.cid = cid;
            this.did = did;
        }

        public int getTid() {
            return tid;
        }

        public int getCid() {
            return cid;
        }

        public int getDid() {
            return did;
        }
    }

    private static class ScheduleTeam {
        private final int tid;
        private final SeasonAttributes seasonAttrs;

        public ScheduleTeam(int tid, SeasonAttributes seasonAttrs) {
            this.tid = tid;
            this.seasonAttrs = seasonAttrs;
        }
    }

    private static class SeasonAttributes {
        private final int did;
        private final int cid;

        public SeasonAttributes(int did, int cid) {
            this.did = did;
            this.cid = cid;
        }
    }
}
