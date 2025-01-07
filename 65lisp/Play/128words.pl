# this gets basically 67% on sherlock or sweden!
# it's like "theoretical" easy limit
# using 128 most common words, assumimg space before/after

while(<>) {
#    s/( the| and| that| to| of| was| i| in| it| a| you| his| he| have| had| with| is| which| there| holmes| for| this| said| not| as| at| but| from| would| been| my| were| could| upon| we| one| him| all| me| what| your| be| are| no| on| will| some| very| then| her| when| should| so| man| into| little| she| well| an| out| watson| before| they| our| has| more| down| can| see| about| nothing| if| who| them| only| come| over| other| now| do| by| think| here| time| mr| never| know| their| house| face| sir| came| did| or| than| matter| us| where| door| last| must| something| after| room| shall| however| morning| these| case| first| through| may| its| two| back| friend| sherlock| thought| up| any| himself| heard| found| night| hand| tell| might| certainly)/#[$1]/ig;

    s/( the\b| and\b| that\b| to\b| of\b| was\b| i\b| in\b| it\b| a\b| you\b| his\b| he\b| have\b| had\b| with\b| is\b| which\b| there\b| holmes\b| for\b| this\b| said\b| not\b| as\b| at\b| but\b| from\b| would\b| been\b| my\b| were\b| could\b| upon\b| we\b| one\b| him\b| all\b| me\b| what\b| your\b| be\b| are\b| no\b| on\b| will\b| some\b| very\b| then\b| her\b| when\b| should\b| so\b| man\b| into\b| little\b| she\b| well\b| an\b| out\b| watson\b| before\b| they\b| our\b| has\b| more\b| down\b| can\b| see\b| about\b| nothing\b| if\b| who\b| them\b| only\b| come\b| over\b| other\b| now\b| do\b| by\b| think\b| here\b| time\b| mr\b| never\b| know\b| their\b| house\b| face\b| sir\b| came\b| did\b| or\b| than\b| matter\b| us\b| where\b| door\b| last\b| must\b| something\b| after\b| room\b| shall\b| however\b| morning\b| these\b| case\b| first\b| through\b| may\b| its\b| two\b| back\b| friend\b| sherlock\b| thought\b| up\b| any\b| himself\b| heard\b| found\b| night\b| hand\b| tell\b| might\b| certainly)/#/ig;
    s/\# /\#/g;
    print;
}
