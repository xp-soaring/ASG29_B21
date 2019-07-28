-- B21
-- #########################################################################################
-- ##                  POLAR SETTINGS FOR GLIDER                                     #######
-- #########################################################################################
-- # ASK21                                                                                 #
-- points from polar curve { speed kps, sink m/s }                                      -- #
project_settings.polar = {                                                              -- #
    { 65.0, 0.8 },                                                                      -- #
    { 70.0, 0.75 },                                                                     -- #
    { 80.0, 0.7 },                                                                      -- #
    { 90.0, 0.76 },                                                                     -- #
    { 100.0, 0.78 },                                                                    -- #
    { 120.0, 1.15 },                                                                    -- #
    { 140.0, 1.75 },                                                                    -- #
    { 160.0, 2.6 },                                                                     -- #
    { 180.0, 3.5 },                                                                     -- #
    { 200.0, 4.9 },                                                                     -- #
    { 250.0, 10.0 } -- backstop, off end of published polar                             -- #
}                                                                                       -- #
--                                                                                      -- #
project_settings.polar_weight_empty_kg = 487 -- ASK21 360kg empty + crew etc            -- #
project_settings.polar_weight_full_kg = 600 -- max weight, but no ballast anyway        -- #
--                                                                                      -- #
project_settings.polar_stf_best_kph = 97 -- speed to fly in zero sink (ASK21)           -- #
project_settings.polar_stf_2_kph = 130    -- speed to fly in 2 m/s sink (ASK21)         -- #
                                                                                        -- #
-- #                                                                                    -- #
-- #########################################################################################
-- ### END OF POLAR SETTINGS                                                         #######
-- #########################################################################################

