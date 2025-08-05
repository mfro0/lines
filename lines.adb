with Ada.Unchecked_Conversion;
with Interfaces.C; use Interfaces.C;
with System;
with Ada.Text_IO;
with GEM; use GEM;


procedure Lines is
    package C renames Interfaces.C; use C;
    
    -- Data
    type Point is record
        x, y : C.short;
    end record;

    type Line is Record
        p1, p2  : Point;
        color   : C.short;
    end Record;

    Max_Trail : constant := 25;
    Trail     : array (1 .. Max_Trail) of Line :=
        (others => (p1 => (x => -1, y => -1),
                    p2 => (x => -1, y => -1),
                    others => 0));

    Colors    : constant array (1 .. Max_Trail) of C.unsigned_short := (16#F800#,
                                                                        16#C000#,
                                                                        16#9000#,
                                                                        16#6000#,
                                                                        16#3000#,
                                                                        others => 0);

    -- Handles
    Vdi_Handle  : aliased C.short;
    Win         : C.short;
    Work_Area   : Rectangle;
    app_id      : C.short;

    procedure Update_Trail(New_Line : Line) is
    begin
        for i in reverse Trail'First + 1 .. Trail'Last loop
            Trail(i) := Trail(i - 1);
        end loop;
        Trail(1) := New_Line;
    end Update_Trail;

    procedure Draw_Trail is
        Points : array(1 .. 4) of aliased C.short;
    begin
        for i in Trail'First .. Trail'Last - 1 loop
            if Trail(i + 1).p1.x >= 0 then
                vsl_color(Vdi_Handle, 1);
                Points(1) := Trail(i).p1.x + Work_Area.x;
                Points(2) := Trail(i).p1.y + Work_Area.y;
                Points(3) := Trail(i).p2.x + Work_Area.x;
                Points(4) := Trail(i).p2.y + Work_Area.y;
                vsl_color(Vdi_Handle, Trail(i).color);
                v_pline(Vdi_Handle, 2, Points(Points'First)'Access);
            end if;
        end loop;
    end Draw_Trail;

    function Max(a, b : C.short) return C.short is
    begin
        if a > b then
            return a;
        else
            return b;
        end if;
    end Max;

    function Min(a, b : C.short) return C.short is
    begin
        if a < b then
            return a;
        else
            return b;
        end if;
    end Min;

    function Rect_Intersect(R1 : in Rectangle; R2 : in out Rectangle) return Boolean is
        tx, ty, tw, th      : C.short;
        Ret                 : Boolean;
    begin
        tx := Max(R2.x, R1.x);
        tw := Min(R2.x + R2.w, R1.x + R1.w) - tx;

        Ret := (0 < tw);

        if Ret then
            ty := Max(R2.y, R1.y);
            th := Min(R2.y + R2.h, R1.y + R1.h) - ty;

            Ret := (0 < th);

            if Ret then
                R2.x := tx;
                R2.y := ty;
                R2.w := tw;
                R2.h := th;
            end if;
        end if;
        return Ret;
    end Rect_Intersect;

    procedure Redraw_Window is
        Clip : array (1 .. 4) of aliased C.short;

    begin
        declare
            r2  : Rectangle;
        begin
            wind_get(Win, WF_FIRSTXYWH, r2.x'Access, r2.y'Access, r2.w'Access, r2.h'Access);

            while r2.w > 0 and r2.h > 0 loop
                if Rect_Intersect(Work_Area, r2) then
                    Clip(1) := r2.x;
                    Clip(2) := r2.y;
                    Clip(3) := r2.x + r2.w - 1;
                    Clip(4) := r2.y + r2.h - 1;
                    vs_clip(Vdi_Handle, 1, Clip(Clip'First)'Access);
                    vsf_interior(Vdi_Handle, FIS_SOLID);
                    vsf_color(Vdi_Handle, 1);
                    vr_recfl(Vdi_Handle, Clip(Clip'First)'Access);
                    Draw_Trail;
                    vs_clip(Vdi_Handle, 0, Clip(Clip'First)'Access);
                end if;
                wind_get(Win, WF_NEXTXYWH, r2.x'Access, r2.y'Access, r2.w'Access, r2.h'Access);
            end loop;
        end;
    end Redraw_Window;

    procedure Send_Redraw(Win : C.short; x, y, w, h : C.short) is
        Message : Array(0 .. 7) of aliased C.short := (WM_REDRAW, x, y, w, h, others => 0);
    begin
        appl_write(app_id, 16, Message(0)'Access);
    end Send_Redraw;
    
    col     : C.short := 0;
begin
    app_id := appl_init;
    declare
        Work_In  : Work_Array := (10 => 2, others => 1);
        Work_Out : Int57_Array;
        Dummy    : aliased C.short := 0;
    begin
        Vdi_Handle := graf_handle(Dummy'Access, Dummy'Access, Dummy'Access, Dummy'Access);

        v_opnvwk(Work_In, Vdi_Handle'Access, Work_Out);
        graf_mouse(ARROW, System.Null_Address);
    end;

    Win := wind_create(NAME + CLOSER + MOVER + FULLER + SIZER, 50, 50, 320, 200);
    wind_open(Win, 50, 50, 320, 200);
    wind_get(Win, WF_CURRXYWH, Work_Area.x'Access, Work_Area.y'Access, Work_Area.w'Access, Work_Area.h'Access);

    -- Main loop
    declare
        Msg         : aliased Message_Array;
        Quit        : Boolean := False;
        MX, MY      : aliased C.short := 0;
        Dummy       : C.short;
        p1          : Point := (10, 10);
        p2          : Point := (Work_Area.w - 10, Work_Area.h - 10);
        dx1         : C.short := 3;
        dy1         : C.short := 4;
        dx2         : C.short := -3;
        dy2         : C.short := -5;
        butdown     : C.short;
        Timer_MS    : C.unsigned_long := 20;
        Mb_Return, Key_State, Key_Return, Ret : aliased C.short;
    begin
        loop
            p1.x := p1.x + dx1; if p1.x >= Work_Area.w or p1.x < 0 then dx1 := -dx1; end if;
            p1.y := p1.y + dy1; if p1.y >= Work_Area.h or p1.y < 0 then dy1 := -dy1; end if;
            p2.x := p2.x + dx2; if p2.x >= Work_Area.w or p2.x < 0 then dx2 := -dx2; end if;
            p2.y := p2.y + dy2; if p2.y >= Work_Area.h or p2.y < 0 then dy2 := -dy2; end if;

            -- Random point inside work area
            Update_Trail((p1, p2, col));
            col := (col + 1) mod 255;

            Dummy := evnt_multi(MU_MESAG + MU_BUTTON + MU_KEYBD + MU_TIMER,
                                1, 1, butdown,
                                0, 0, 0, 0, 0,
                                0, 0, 0, 0, 0,
                                Msg'Access, Timer_MS, MX'Access, MY'Access,
                                Mb_Return'Access, Key_State'Access,
                                Key_Return'Access, Ret'Access);
            begin
                if Msg(0) = WM_REDRAW then
                    wind_update(1);
                    Redraw_Window;
                    wind_update(0);
                elsif Msg(0) = WM_MOVED or
                      Msg(0) = WM_SIZED then
                    wind_set(Win, WF_CURRXYWH, Msg(4), Msg(5), Msg(6), Msg(7));
                    wind_get(Win, WF_CURRXYWH, Work_Area.x'Access, Work_Area.y'Access,
                                               Work_Area.w'Access, Work_Area.h'Access);
                    Send_Redraw(Win, Msg(4), Msg(5), Msg(6), Msg(7));
                elsif Msg(0) = WM_FULLED then
                    null;
                elsif Msg(0) = WM_CLOSED then
                    Quit := True;
                end if;
            end;
            exit when Quit;
        end loop;
    end;

    wind_close(Win);
    wind_delete(Win);
    v_clsvwk(Vdi_Handle);
    appl_exit;
end Lines;
