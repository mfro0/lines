with Ada.Unchecked_Conversion;
with Interfaces.C; use Interfaces.C;
with System;
with Ada.Text_IO;
with GEM; use GEM;


procedure Lines is
    package C renames Interfaces.C;

    -- Data
    type Point is record
        x, y : C.short;
    end record;

    type Line is Record
        p1, p2  : Point;
    end Record;

    Max_Trail : constant := 30;
    Trail     : array (1 .. Max_Trail) of Line :=
        (others => (p1 => (x => -1, y => -1), p2 => (x => -1, y => -1)));

--    Colors    : constant array (1 .. Max_Trail) of C.short :=
--       (C.unsigned_short(16#F800#), C.short(16#C000#), C.short(16#9000#),
--        C.short(16#6000#), C.short(16#3000#));

    -- Handles
    Vdi_Handle : aliased C.short;
    Win        : C.short;
    Work_Area  : GRECT;

    procedure Update_Trail(New_Line : Line) is
    begin
        for I in reverse Trail'First + 1 .. Trail'Last loop
            Trail(I) := Trail(I - 1);
        end loop;
        Trail(1) := New_Line;
    end Update_Trail;

    procedure Draw_Trail is
        Points : array (1 .. 4) of aliased C.short;
    begin
        for I in Trail'First .. Trail'Last - 1 loop
            if Trail(I + 1).p1.x >= 0 then
                vsl_color (Vdi_Handle, 1);
                Points(1) := C.short (Trail(I).p1.x);
                Points(2) := C.short (Trail(I).p1.y);
                Points(3) := C.short (Trail(I).p2.x);
                Points(4) := C.short (Trail(I).p2.y);
                v_pline(Vdi_Handle, 2, Points (Points'First)'Access);
            end if;
        end loop;
    end Draw_Trail;

    procedure Redraw_Window is
        Clip : array (1 .. 4) of aliased C.short;
    begin
        Clip(1) := C.short (Work_Area.g_x);
        Clip(2) := C.short (Work_Area.g_y);
        Clip(3) := C.short (Work_Area.g_x + Work_Area.g_w - 1);
        Clip(4) := C.short (Work_Area.g_y + Work_Area.g_h - 1);
        vs_clip (Vdi_Handle, 1, Clip(Clip'First)'Access);
        vsf_interior (Vdi_Handle, FIS_SOLID);
        vsf_color (Vdi_Handle, 0);
        vr_recfl (Vdi_Handle, Clip(Clip'First)'Access);
        Draw_Trail;
        vs_clip (Vdi_Handle, 0, Clip(Clip'First)'Access);
    end Redraw_Window;

    app_id  : C.short;
begin
    app_id := appl_init;
    declare
        Work_In  : Work_Array := (10 => 2, others => 1);
        Work_Out : Int57_Array;
        Dummy    : aliased C.short := 0;
    begin
        Vdi_Handle := graf_handle (Dummy'Access, Dummy'Access, Dummy'Access, Dummy'Access);

        v_opnvwk (Work_In, Vdi_Handle'Access, Work_Out);
    end;

    Win := wind_create(NAME + CLOSER + MOVER + FULLER, 50, 50, 320, 200);
    wind_open(Win, 50, 50, 320, 200);

    declare
        X, Y, W, H : aliased C.short;
    begin
        wind_get(Win, 4, X'Access, Y'Access, W'Access, H'Access);
        Work_Area.g_x := X;
        Work_Area.g_y := Y;
        Work_Area.g_w := W;
        Work_Area.g_h := H;
    end;

    -- Main loop
    declare
        Msg     : aliased Message_Array;
        Quit    : Boolean := False;
        MX, MY  : aliased C.short := 0;
        Dummy	: C.short;
        p1 : Point := (Work_Area.g_x + 10, Work_Area.g_y + 10);
        p2 : Point := (Work_Area.g_x + Work_Area.g_w - 10,
                       Work_Area.g_y + Work_Area.g_h - 10);
        dx1 : C.short := 3;
        dy1 : C.short := 4;
        dx2 : C.short := -3;
        dy2 : C.short := -4;
        butdown : C.short;
        Timer_MS    : C.unsigned_long := 50;
        Mb_Return, Key_State, Key_Return, Ret : aliased C.short;
    begin
        loop
            p1.x := p1.x + dx1; if p1.x >= Work_Area.g_x + Work_Area.g_w or p1.x < Work_Area.g_x then dx1 := -dx1; end if;
            p1.y := p1.y + dy1; if p1.y >= Work_Area.g_y + Work_Area.g_h or p1.y < Work_Area.g_y then dy1 := -dy1; end if;
            p2.x := p2.x + dx2; if p2.x >= Work_Area.g_x + Work_Area.g_w or p2.x < Work_Area.g_x then dx2 := -dx2; end if;
            p2.y := p2.y + dy2; if p2.y >= Work_Area.g_y + Work_Area.g_h or p2.y < Work_Area.g_y then dy2 := -dy2; end if;

            -- Random point inside work area
            Update_Trail((p1, p2));

            Dummy := evnt_multi(MU_MESAG + MU_BUTTON + MU_KEYBD + MU_TIMER,
                                1, 1, butdown,
                                0, 0, 0, 0, 0,
                                0, 0, 0, 0, 0,
                                Msg'Access, Timer_MS, MX'Access, MY'Access,
                                Mb_Return'Access, Key_State'Access,
                                Key_Return'Access, Ret'Access);
            begin
                if Msg(0) = WM_REDRAW then
                    wind_update (1);
                    Redraw_Window;
                    wind_update (0);
                elsif Msg(0) = WM_CLOSED then
                    Quit := True;
                end if;
            end;

            Redraw_Window;
            exit when Quit;
        end loop;
    end;

    wind_close (Win);
    wind_delete (Win);
    v_clsvwk (Vdi_Handle);
    appl_exit;
end Lines;
