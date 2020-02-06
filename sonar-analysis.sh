#!/bin/sh

# Source environment
#source ~/.bashrc

export SONAR_VERSION="4.1.0.1829"

#Download the sonar scanner binaries
if [ ! -f sonarscanner.zip ]; then
    curl -H "Accept: application/zip" https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SONAR_VERSION.zip -o sonarscanner.zip
    unzip sonarscanner.zip
fi

SONAR_HOME=`find "$PWD" -type d -name 'sonar-scanner*'`
if [[ ! "$SONAR_HOME" =~ sonar-scanner ]]; then
    echo "Failed to setup sonar binaries"
    exit
else
    echo "SONAR_HOME: $SONAR_HOME"
fi

#Change to use absolute paths
export PATH=$PATH:$SONAR_HOME/bin

# assuming below structure
# $project-root/sonar-analysis, navigating to project root
cd ../

echo "Running sonar-scanner from: $PWD"


usageRepoAnalysis() {

   echo "----------------Repo Analysis---------------"
   echo "$0 repo --long-lived-branch=(Optional)longLivedBranch --sonar-server=(Optional)sonarServerUrl --sonar-login-token=generatedLoginToken"
   echo "  =>\t --long-lived-branch     | Optional | Name of current branch that needs to be considered as long-lived and for which analysis has to be run | -Dsonar.branch.name=currentBranch, -Dsonar.branch.longLivedBranches.regex=currentBranch"
   echo "  =>\t --sonar-server          | Optional | the server URL where sonarqube is hosted. If not provided takes default value from sonar-project.properties | -Dsonar.host.url=sonarServerUrl"
   echo "  =>\t --sonar-login-token     | Login token to push analysis results to sonar server | -Dsonar.login=sonarLoginToken"
   echo ""
}

usageBranchAnalysis() {

   echo "--------------Branch Analysis---------------"
   echo "$0 branch --current-branch=currentBranch --target-branch=targetBranch --sonar-server=(Optional)sonarServerUrl --sonar-login-token=generatedLoginToken"
   echo "  =>\t --current-branch        | Name of current branch name for which analysis has to be run | -Dsonar.branch.name=currentBranch"
   echo "  =>\t --target-branch         | Name of the branch where you intend to merge your short-lived branch at the end of its life. This should exist sonar-server | -Dsonar.branch.target=targetBranch"
   echo "  =>\t --sonar-server          | Optional | the server URL where sonarqube is hosted. If not provided takes default value from sonar-project.properties | -Dsonar.host.url=sonarServerUrl"
   echo "  =>\t --sonar-login-token     | Login token to push analysis results to sonar server | -Dsonar.login=sonarLoginToken"
   echo ""
}

usagePRAnalysis() {

   echo "-----------------PR Analysis-----------------"
   echo "$0 pr --pr-current-branch=prCurrentBranch --pr-base-branch=prBaseBranch --pr-key=pullRequestKey --github-repo-slug=githubRepoSlug --sonar-server=(Optional)sonarServerUrl --sonar-login-token=generatedLoginToken"
   echo "  =>\t --pr-current-branch     | Name of pull request branch name for which analysis has to be run | -Dsonar.pullrequest.branch=prCurrentBranch"
   echo "  =>\t --pr-base-branch        | The long-lived branch into which the PR will be merged. This branch should exist on sonar-server | -Dsonar.pullrequest.base=prBaseBranch"
   echo "  =>\t --pr-key                | Unique identifier of your PR. Must correspond to the key of the PR in GitHub | -Dsonar.pullrequest.key=pullRequestKey"
   echo "  =>\t --github-repo-slug      | Identification of the repository. Format is: <organisation/repo> | -Dsonar.pullrequest.github.repository=githubRepoSlug"
   echo "  =>\t --sonar-server          | Optional | the server URL where sonarqube is hosted. If not provided takes default value from sonar-project.properties | -Dsonar.host.url=sonarServerUrl"
   echo "  =>\t --sonar-login-token     | Login token to push analysis results to sonar server | -Dsonar.login=sonarLoginToken"
   echo ""
}

usage() {

   echo "Usage"
   usageRepoAnalysis
   usageBranchAnalysis
   usagePRAnalysis
   exit 1
}

getSonarParams() {
    
    [ ! -z "$currentBranch" ]     && SONAR_PARAMS+=("-Dsonar.branch.name=$currentBranch")
    [ ! -z "$targetBranch" ]      && SONAR_PARAMS+=("-Dsonar.branch.target=$targetBranch")
    [ ! -z "$prCurrentBranch" ]   && SONAR_PARAMS+=("-Dsonar.pullrequest.branch=$prCurrentBranch")
    [ ! -z "$prBaseBranch" ]      && SONAR_PARAMS+=("-Dsonar.pullrequest.base=$prBaseBranch")
    [ ! -z "$pullRequestKey" ]    && SONAR_PARAMS+=("-Dsonar.pullrequest.key=$pullRequestKey")
    [ ! -z "$githubRepoSlug" ]    && SONAR_PARAMS+=("-Dsonar.pullrequest.github.repository=$githubRepoSlug")
    [ ! -z "$sonarServerUrl" ]    && SONAR_PARAMS+=("-Dsonar.host.url=$sonarServerUrl")
    [ ! -z "$longLivedBranch" ]   && SONAR_PARAMS+=("-Dsonar.branch.name=$longLivedBranch")
    [ ! -z "$sonarLoginToken" ]   && SONAR_PARAMS+=("-Dsonar.login=$sonarLoginToken")
}


parseArgs() {

    while [ $# -gt 0 ]; do
        case "$1" in
            --current-branch=*)         currentBranch="${1#*=}" ;;      # sonar.branch.name
            --target-branch=*)          targetBranch="${1#*=}" ;;       # sonar.branch.target
            --pr-current-branch=*)      prCurrentBranch="${1#*=}" ;;    # sonar.pullrequest.branch
            --pr-base-branch=*)         prBaseBranch="${1#*=}" ;;       # sonar.pullrequest.base
            --pr-key=*)                 pullRequestKey="${1#*=}" ;;     # sonar.pullrequest.key
            --github-repo-slug=*)       githubRepoSlug="${1#*=}" ;;     # sonar.pullrequest.github.repository
            --sonar-server=*)           sonarServerUrl="${1#*=}" ;;     # sonar.host.url
            --long-lived-branch=*)      longLivedBranch="${1#*=}" ;;    # sonar.branch.name
            --sonar-login-token=*)      sonarLoginToken="${1#*=}" ;;    # sonar.login
            *)                          echo "Invalid argument(s) passed"; usage; exit 1 ;;
        esac
        shift
    done

    getSonarParams
}


execSonar() {

    echo "Issuing sonar-scanner command from: " `pwd`
    sonar-scanner ${SONAR_PARAMS[@]}
}

repoAnalysis() {

    if [ ! -z "$longLivedBranch" ]; then
      SONAR_PARAMS+=("-Dsonar.branch.name=$longLivedBranch")
      SONAR_PARAMS+=("-Dsonar.branch.longLivedBranches.regex=$longLivedBranch")
    fi
    execSonar
}

branchAnalysis() {
    
    if [ -z "$currentBranch" ] || [ -z "$targetBranch" ]
    then
       echo "one or more parameters missing for branch analysis. see usage below"; usageBranchAnalysis; exit 1;
    fi
    execSonar
}


prAnalysis() {

    if [ -z "$prCurrentBranch" ] || [ -z "$prBaseBranch" ] || [ -z "$pullRequestKey" ]
    then
       echo "one or more parameters missing for pr analysis to github. see usage below"; usagePRAnalysis; exit 1;
    fi
    execSonar
}

SONAR_PARAMS=()

case $1
in
   repo)    shift 1; parseArgs $@; repoAnalysis ;;
   branch)  shift 1; parseArgs $@; branchAnalysis ;;
   pr)      shift 1; parseArgs $@; prAnalysis ;;
   *)       echo "Invalid argument passed" ; usage ;;
esac
