-- B21
-- #########################################################################################
-- ##                  POLAR SETTINGS FOR GLIDER                                     #######
-- #########################################################################################
-- # ASG29                                                                                 #
-- points from polar curve { speed kps, sink m/s }                                      -- #
project_settings.polar = {                                                              -- #
    {65, 0.8},
    {75,0.5},
    {80,0.48},
    {85,0.47},
    {90,0.49},
    {95,0.52},
    {100,0.55},
    {105,0.58},
    {110,0.63},
    {125,0.8},
    {150,1.25},
    {175,1.85},
    {200, 3}, -- guessing
    { 250.0, 10.0 } -- backstop, off end of published polar                             -- #
}                                                                                       -- #
--                                                                                      -- #
project_settings.polar_weight_empty_kg = 360 -- ASG29 280kg empty + crew etc            -- #
project_settings.polar_weight_full_kg = 585 -- max weight                               -- #
--                                                                                      -- #
project_settings.polar_stf_best_kph = 100 -- speed to fly in zero sink (ASG29)           -- #
project_settings.polar_stf_2_kph = 137    -- speed to fly in 2 m/s sink (ASG29)         -- #
                                                                                        -- #
-- #                                                                                    -- #
-- #########################################################################################
-- ### END OF POLAR SETTINGS                                                         #######
-- #########################################################################################

