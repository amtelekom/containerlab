*** Comments ***
Regression suite for the destroy leak of var-conditional nodes:
- a template-var gated node is deployed
- a destroy that parses the topology WITHOUT --vars cannot know the node
- containerlab must still remove the leftover container via the
  label-based destroy sweep, and clean the lab directory


*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../common.robot

Suite Setup         Run    ${CLAB_BIN} --runtime ${runtime} destroy --name ${lab-name} --cleanup -y
Suite Teardown      Run    ${CLAB_BIN} --runtime ${runtime} destroy --name ${lab-name} --cleanup -y


*** Variables ***
${runtime}          docker
${lab-name}         leak-regression
${topo}             35-destroy-leak.clab.yml
${full-vars}        35-destroy-leak.vars.full.yml


*** Test Cases ***
Deploy lab including the var-gated extra node
    ${rc}    ${output} =    Run Clab Command
    ...    deploy -t ${CURDIR}/${topo} --vars ${CURDIR}/${full-vars}
    Should Be Equal As Integers    ${rc}    0
    Lab Label Lists Containers    ${lab-name}    clab-${lab-name}-n1    clab-${lab-name}-extra

Destroy by name without vars removes the leftover container
    ${rc}    ${output} =    Run Clab Command
    ...    destroy --name ${lab-name} --cleanup -y
    Should Be Equal As Integers    ${rc}    0

    Lab Label Lists No Containers    ${lab-name}
    Directory Should Not Exist    ${CURDIR}/clab-${lab-name}


*** Keywords ***
Run Clab Command
    [Arguments]    ${args}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    ${CLAB_BIN} --runtime ${runtime} ${args} 2>&1
    Log    ${output}
    RETURN    ${rc}    ${output}

Lab Label Lists Containers
    [Arguments]    ${lab}    @{expected}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    docker ps -a --filter label=containerlab=${lab} --format '{{.Names}}'
    Should Be Equal As Integers    ${rc}    0
    FOR    ${name}    IN    @{expected}
        Should Contain    ${output}    ${name}
    END

Lab Label Lists No Containers
    [Arguments]    ${lab}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    docker ps -a --filter label=containerlab=${lab} --format '{{.Names}}'
    Should Be Equal As Integers    ${rc}    0
    Should Not Contain    ${output}    clab-
