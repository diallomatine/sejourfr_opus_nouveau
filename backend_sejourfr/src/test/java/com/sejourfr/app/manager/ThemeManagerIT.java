package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.ThemeRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ThemeManagerIT extends AbstractIntegrationTest {

    @Autowired
    private ThemeManager themeManager;

    @Autowired
    private ThemeRepository themeRepository;

    @Autowired
    private TestData testData;

    @Test
    void saveAndFindById() {
        Theme t = testData.theme(Module.TCF, "saveFind", "Thème save");
        assertThat(t.getId()).isNotNull();

        Optional<Theme> found = themeManager.findById(t.getId());
        assertThat(found).isPresent();
        assertThat(found.get().getModule()).isEqualTo(Module.TCF);
        assertThat(found.get().getName()).isEqualTo("Thème save");
    }

    @Test
    void findByIdAbsentReturnsEmpty() {
        assertThat(themeManager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void findAllOrderedByDisplayOrderSortsAscending() {
        Theme high = order("allHigh", 300);
        Theme low = order("allLow", 100);
        Theme mid = order("allMid", 200);
        Set<UUID> mine = Set.of(high.getId(), low.getId(), mid.getId());

        List<Theme> all = themeManager.findAllOrderedByDisplayOrder();

        // Global : la liste entière est triée par displayOrder croissant.
        for (int i = 1; i < all.size(); i++) {
            assertThat(all.get(i).getDisplayOrder())
                    .isGreaterThanOrEqualTo(all.get(i - 1).getDisplayOrder());
        }
        // Local : mes 3 thèmes ressortent dans l'ordre low < mid < high.
        List<UUID> mineOrdered = all.stream()
                .map(Theme::getId)
                .filter(mine::contains)
                .collect(Collectors.toList());
        assertThat(mineOrdered).containsExactly(low.getId(), mid.getId(), high.getId());
    }

    @Test
    void findByModuleOrderedFiltersAndSorts() {
        Theme civHigh = mod(Module.CIVIQUE, "modCivHigh", 300);
        Theme civLow = mod(Module.CIVIQUE, "modCivLow", 100);
        Theme tcf = mod(Module.TCF, "modTcf", 50);

        List<Theme> civique = themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE);
        List<UUID> ids = civique.stream().map(Theme::getId).collect(Collectors.toList());

        assertThat(ids).doesNotContain(tcf.getId());
        // civLow (100) doit précéder civHigh (300) dans le résultat trié.
        assertThat(ids.indexOf(civLow.getId()))
                .isLessThan(ids.indexOf(civHigh.getId()));
        assertThat(civique).allMatch(t -> t.getModule() == Module.CIVIQUE);
    }

    @Test
    void existsByCodeMatchesExact() {
        Theme t = testData.theme(Module.CIVIQUE, "existsCode", "Thème exists");
        assertThat(themeManager.existsByCode(t.getCode())).isTrue();
        assertThat(themeManager.existsByCode("code-absent-" + UUID.randomUUID())).isFalse();
    }

    @Test
    void deleteRemovesRow() {
        Theme t = testData.theme(Module.TCF, "delTheme", "Thème delete");
        UUID id = t.getId();
        assertThat(themeManager.findById(id)).isPresent();

        themeManager.delete(t);

        assertThat(themeManager.findById(id)).isEmpty();
    }

    @Test
    void duplicateCodeViolatesUniqueConstraint() {
        Theme a = testData.theme(Module.CIVIQUE, "dupTheme", "A");
        Theme b = new Theme();
        b.setModule(Module.CIVIQUE);
        b.setCode(a.getCode());   // même code → viole uk_theme_code
        b.setName("B");
        b.setDisplayOrder(0);

        assertThatThrownBy(() -> themeRepository.saveAndFlush(b))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    private Theme order(String code, int displayOrder) {
        return mod(Module.CIVIQUE, code, displayOrder);
    }

    private Theme mod(Module module, String code, int displayOrder) {
        Theme t = new Theme();
        t.setModule(module);
        t.setCode(code + "-" + UUID.randomUUID());
        t.setName("Thème " + code);
        t.setDisplayOrder(displayOrder);
        return themeManager.save(t);
    }
}
