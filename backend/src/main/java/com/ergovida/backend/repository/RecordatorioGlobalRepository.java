package com.ergovida.backend.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ergovida.backend.model.RecordatorioGlobal;

public interface RecordatorioGlobalRepository extends JpaRepository<RecordatorioGlobal, Long> {

    List<RecordatorioGlobal> findByActivoTrueOrderByHoraAsc();

    List<RecordatorioGlobal> findAllByOrderByHoraAsc();
}
