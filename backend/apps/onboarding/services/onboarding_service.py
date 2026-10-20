"""
FactoryOS AI — Transactional Onboarding Service
Phase 2: Universal Manufacturing Onboarding

Performs validation and atomic creation of:
- Company (Organization)
- Factory
- Manufactured Products
- Raw Materials
- Process Stages
- Production Lines & Machines
- Shifts & Capacity
- Initial Metric Snapshot
"""
import uuid
import re
from django.db import transaction
from django.utils.text import slugify
from rest_framework.exceptions import ValidationError

from apps.factories.models import (
    Organization,
    Factory,
    Product,
    RawMaterial,
    ProcessStage,
    ProductionLine,
    Machine,
    ShiftConfiguration,
    FactoryMetricSnapshot,
    ConfigurationStatus,
    LineStatus,
)
from apps.onboarding.models import OnboardingDraft, DraftStatus

def generate_unique_factory_code(base_name: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9]", "", base_name).upper()
    prefix = cleaned[:4] if len(cleaned) >= 4 else "FACT"
    short_uuid = uuid.uuid4().hex[:4].upper()
    code = f"FAC-{prefix}-{short_uuid}"
    while Factory.objects.filter(code=code).exists():
        short_uuid = uuid.uuid4().hex[:4].upper()
        code = f"FAC-{prefix}-{short_uuid}"
    return code

def generate_unique_company_slug(name: str) -> str:
    base_slug = slugify(name) or "enterprise"
    slug = base_slug
    counter = 1
    while Organization.objects.filter(slug=slug).exists():
        slug = f"{base_slug}-{counter}"
        counter += 1
    return slug

class OnboardingService:
    """
    Transactional onboarding orchestrator.
    Guarantees atomic creation of enterprise hierarchy and equipment topology.
    """

    @classmethod
    @transaction.atomic
    def activate_factory(cls, wizard_data: dict, draft_id: str = None) -> Factory:
        # 0. Validate draft if supplied
        draft_obj = None
        if draft_id:
            try:
                draft_obj = OnboardingDraft.objects.get(id=draft_id)
                if draft_obj.status == DraftStatus.ACTIVATED:
                    raise ValidationError({
                        "draft_id": f"Onboarding draft '{draft_obj.name}' has already been activated into live production. Duplicate submission is blocked."
                    })
            except OnboardingDraft.DoesNotExist:
                raise ValidationError({"draft_id": f"Specified onboarding draft with ID {draft_id} does not exist."})

        # 1. Validate mandatory sections
        company_data = wizard_data.get("company", {})
        factory_data = wizard_data.get("factory", {})

        company_name = company_data.get("name", "").strip()
        factory_name = factory_data.get("name", "").strip()

        if not company_name:
            raise ValidationError({"company": "Company name is required."})
        if not factory_name:
            raise ValidationError({"factory": "Factory name is required."})

        # 2. Resolve or Create Company (Organization)
        company_id = company_data.get("id")
        if company_id:
            try:
                org = Organization.objects.get(id=company_id)
            except Organization.DoesNotExist:
                raise ValidationError({"company": f"Specified company with ID {company_id} does not exist."})
        else:
            # Check by name first
            existing = Organization.objects.filter(name__iexact=company_name).first()
            if existing:
                org = existing
            else:
                org = Organization.objects.create(
                    name=company_name,
                    slug=generate_unique_company_slug(company_name),
                    description=company_data.get("description", ""),
                    website=company_data.get("website", ""),
                    contact_email=company_data.get("contact_email", ""),
                )

        # Duplicate factory check within organization
        if Factory.objects.filter(organization=org, name__iexact=factory_name, is_active=True).exists():
            raise ValidationError({
                "factory": f"A factory named '{factory_name}' already exists in organization '{org.name}'. Please choose a distinct factory name to avoid duplicates."
            })

        # 3. Create Factory
        code = factory_data.get("code", "").strip()
        if code and Factory.objects.filter(code=code).exists():
            raise ValidationError({
                "factory": f"Factory code '{code}' is already assigned to an existing facility. Please specify a unique code."
            })
        if not code:
            code = generate_unique_factory_code(factory_name)

        industry_type = factory_data.get("industry_type", "CUSTOM")
        industry_custom = factory_data.get("industry_custom", "")
        factory_type = factory_data.get("factory_type", "PRIMARY_MANUFACTURING")
        manufacturing_model = factory_data.get("manufacturing_model", "DISCRETE")
        location = factory_data.get("location", "Standard Industrial Park")
        country = factory_data.get("country", "USA")
        timezone = factory_data.get("timezone", "UTC")
        operating_hours = factory_data.get("operating_hours", "06:00 - 22:00 (Two 8h Shifts)")
        capabilities = factory_data.get("capabilities", [])
        if not isinstance(capabilities, list):
            capabilities = [str(capabilities)]

        target_daily_capacity = int(factory_data.get("target_daily_capacity", 5000))

        factory = Factory.objects.create(
            organization=org,
            name=factory_name,
            code=code,
            industry_type=industry_type,
            industry_custom=industry_custom,
            factory_type=factory_type,
            manufacturing_model=manufacturing_model,
            configuration_status=ConfigurationStatus.CONFIGURED,
            location=location,
            country=country,
            timezone=timezone,
            operating_hours=operating_hours,
            capabilities=capabilities,
            target_daily_capacity=target_daily_capacity,
            total_production_lines=0,
            active_lines=0,
            is_active=True,
        )

        # 4. Create Products
        products_data = wizard_data.get("products", [])
        for idx, p in enumerate(products_data):
            p_name = p.get("name", "").strip()
            if not p_name:
                continue
            sku = p.get("sku", "").strip() or f"SKU-{factory.code}-{idx+1:02d}"
            # Ensure unique sku per factory
            if Product.objects.filter(factory=factory, sku=sku).exists():
                sku = f"{sku}-{uuid.uuid4().hex[:3]}"
            Product.objects.create(
                factory=factory,
                name=p_name,
                sku=sku,
                description=p.get("description", ""),
                unit_of_measure=p.get("unit_of_measure", "units"),
                target_hourly_rate=int(p.get("target_hourly_rate", 100)),
            )

        # 5. Create Raw Materials
        materials_data = wizard_data.get("raw_materials", [])
        for idx, m in enumerate(materials_data):
            m_name = m.get("name", "").strip()
            if not m_name:
                continue
            m_code = m.get("code", "").strip() or f"RAW-{factory.code}-{idx+1:02d}"
            if RawMaterial.objects.filter(factory=factory, code=m_code).exists():
                m_code = f"{m_code}-{uuid.uuid4().hex[:3]}"
            RawMaterial.objects.create(
                factory=factory,
                name=m_name,
                code=m_code,
                category=m.get("category", "General"),
                unit_of_measure=m.get("unit_of_measure", "kg"),
                safety_stock=float(m.get("safety_stock", 100.0)),
                current_stock=float(m.get("current_stock", 500.0)),
            )

        # 6. Create Process Stages
        stages_data = wizard_data.get("process_stages", [])
        stage_map = {}
        for idx, s in enumerate(stages_data):
            s_name = s.get("name", "").strip()
            if not s_name:
                continue
            seq = s.get("sequence", idx + 1)
            stage_obj = ProcessStage.objects.create(
                factory=factory,
                name=s_name,
                sequence=seq,
                description=s.get("description", ""),
                cycle_time_seconds=int(s.get("cycle_time_seconds", 60)),
                quality_check_required=bool(s.get("quality_check_required", False)),
            )
            stage_map[s_name.lower()] = stage_obj
            stage_map[str(seq)] = stage_obj

        # 7. Create Production Lines and Machines
        lines_data = wizard_data.get("production_lines", [])
        total_created_lines = 0
        active_lines_count = 0

        for idx, l in enumerate(lines_data):
            l_name = l.get("name", "").strip()
            if not l_name:
                continue
            l_code = l.get("code", "").strip() or f"LINE-{idx+1:02d}"
            if ProductionLine.objects.filter(factory=factory, code=l_code).exists():
                l_code = f"{l_code}-{uuid.uuid4().hex[:3]}"

            first_prod = products_data[0].get("name", "Standard Part") if products_data else "Scheduled Item"
            target_hourly = int(l.get("target_hourly_units", 120))
            actual_hourly = int(round(target_hourly * 0.94))
            dept = l.get("department", "General Production").strip() or "General Production"

            line_obj = ProductionLine.objects.create(
                factory=factory,
                name=l_name,
                code=l_code,
                department=dept,
                status=LineStatus.RUNNING,
                current_product=first_prod,
                efficiency_rate=93.5,
                target_hourly_units=target_hourly,
                actual_hourly_units=actual_hourly,
                operator_count=int(l.get("operator_count", 3)),
            )
            total_created_lines += 1
            active_lines_count += 1

            # Create Machines attached to this line
            machines_data = l.get("machines", [])
            for midx, m in enumerate(machines_data):
                m_name = m.get("name", "").strip()
                if not m_name:
                    continue
                m_code = m.get("code", "").strip() or f"M-{l_code}-{midx+1:02d}"
                # Resolve process stage if specified
                stage_ref = m.get("process_stage") or m.get("stage_sequence")
                resolved_stage = None
                if stage_ref:
                    resolved_stage = stage_map.get(str(stage_ref).lower())

                Machine.objects.create(
                    production_line=line_obj,
                    process_stage=resolved_stage,
                    name=m_name,
                    code=m_code,
                    machine_type=m.get("machine_type", "Standard Machine"),
                    rated_power_kw=float(m.get("rated_power_kw", 15.0)),
                    status=LineStatus.RUNNING,
                )

        # Update line totals on factory
        factory.total_production_lines = total_created_lines
        factory.active_lines = active_lines_count
        factory.save(update_fields=["total_production_lines", "active_lines"])

        # 8. Create Operating Shifts
        shifts_data = wizard_data.get("shifts", [])
        for s in shifts_data:
            s_name = s.get("name", "").strip()
            if not s_name:
                continue
            start_t = s.get("start_time", "06:00")
            end_t = s.get("end_time", "14:00")
            days = s.get("operating_days", ["Mon", "Tue", "Wed", "Thu", "Fri"])
            capacity = int(s.get("planned_capacity_units", 1000))
            ShiftConfiguration.objects.create(
                factory=factory,
                name=s_name,
                start_time=start_t,
                end_time=end_t,
                operating_days=days,
                planned_capacity_units=capacity,
            )

        # 9. Create Initial Metric Snapshot for immediate Command Center display
        FactoryMetricSnapshot.objects.create(
            factory=factory,
            overall_oee=91.2,
            availability=95.5,
            performance=96.2,
            quality_rate=99.1,
            energy_consumption_kwh=3200.0,
            active_alerts_count=0,
            active_shifts=max(1, len(shifts_data)),
            planned_units=target_daily_capacity,
            actual_units=int(target_daily_capacity * 0.94),
            scrap_units=int(target_daily_capacity * 0.008),
        )

        # 10. Mark Draft as Activated if supplied
        if draft_id:
            try:
                draft = OnboardingDraft.objects.get(id=draft_id)
                draft.status = DraftStatus.ACTIVATED
                draft.save(update_fields=["status"])
            except OnboardingDraft.DoesNotExist:
                pass

        return factory
