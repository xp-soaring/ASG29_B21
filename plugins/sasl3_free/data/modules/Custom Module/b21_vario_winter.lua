-- B21

print("b21_vario_winter starting")

-- WRITES the needle on the vario_57 gauge listens to this DataRef
local vario_winter_needle = createGlobalPropertyf("b21/vario_winter/needle_fpm", 0.0, false, true, true)

-- READS the TE value from b21_total_energy
local te_fpm = globalPropertyf("b21/total_energy_fpm")

-- 
function update()
    set(vario_winter_needle, get(te_fpm))
end
