with Ada.Unchecked_Conversion;
with Interfaces.C; use Interfaces.C;
with System;
with Ada.Text_IO; use Ada.Text_IO;

procedure Lines is
    package C renames Interfaces.C;

    type Short_Array is array (Positive range <>) of C.short;

    -- AES/VDI Types
    type GRECT is record
        g_x, g_y, g_w, g_h : C.short;
    end record;
    pragma Convention (C, GRECT);

    subtype AES_Id is C.short;

    aes_global : System.Address;
    pragma Import(C, aes_global, "aes_global");

    -- AES Functions
    function appl_init return C.short;
    pragma Import (C, appl_init, "appl_init");

    procedure mt_appl_exit(aes_global : System.Address);
    pragma Import (C, mt_appl_exit, "mt_appl_exit");
    procedure appl_exit is
    begin
        mt_appl_exit(aes_global);
    end appl_exit;

    function  mt_graf_handle (w, h, cw, ch : access C.short; global_aes : System.Address) return C.short;
    pragma Import (C, mt_graf_handle, "mt_graf_handle");
    function graf_handle(w, h, cw, ch : access C.short) return C.short is
    begin
        return mt_graf_handle(w, h, cw, ch, aes_global);
    end graf_handle;

    function mt_wind_create (kind : C.short; x, y, w, h : C.short; aes_global : System.Address) return C.short;
    pragma Import (C, mt_wind_create, "mt_wind_create");
    function wind_create(kind, x, y, w, h : C.short) return C.short is
    begin
        return mt_wind_create(kind, x, y, w, h, aes_global);
    end wind_create;

    procedure mt_wind_open (wh, x, y, w, h : C.short; aes_global : System.Address);
    pragma Import (C, mt_wind_open, "mt_wind_open");
    procedure wind_open(wh, x, y, w, h : C.short) is
    begin
        mt_wind_open(wh, x, y, w, h, aes_global);
    end wind_open;

    procedure mt_wind_close (wh : C.short; aes_global : System.Address);
    pragma Import(C, mt_wind_close, "mt_wind_close");
    procedure wind_close(wh : C.short) is
    begin
        mt_wind_close(wh, aes_global);
    end wind_close;

    procedure mt_wind_delete (wh : C.short; aes_global : System.Address);
    pragma Import(C, mt_wind_delete, "mt_wind_delete");
    procedure wind_delete(wh : C.short) is
    begin
        mt_wind_delete(wh, aes_global);
    end wind_delete;

    procedure mt_wind_get (wh, mode : C.short; x, y, w, h : access C.short; aes_global : System.Address);
    pragma Import (C, mt_wind_get, "mt_wind_get");
    procedure wind_get(wh, mode : C.short; x, y, w, h : access C.short) is
    begin
        mt_wind_get(wh, mode, x, y, w, h, aes_global);
    end wind_get;

    procedure mt_wind_update(mode : C.short; aes_global : System.Address);
    pragma Import (C, mt_wind_update, "mt_wind_update");
    procedure wind_update(mode : C.short) is
    begin
        mt_wind_update(mode, aes_global);
    end wind_update;

    -- VDI Functions
    type Work_Array is array (0 .. 10) of C.short;
    type Int57_Array is array (0 .. 56) of C.short;

    procedure v_opnvwk (work_in : Work_Array; handle : access C.short; work_out : Int57_Array);
    pragma Import (C, v_opnvwk, "v_opnvwk");

    procedure v_clsvwk (handle : C.short);
    pragma Import (C, v_clsvwk, "v_clsvwk");

    procedure v_pline (handle : C.short; count : C.short; points : access C.short);
    pragma Import (C, v_pline, "v_pline");

    procedure vs_clip (handle, on : C.short; rect : access C.short);
    pragma Import (C, vs_clip, "vs_clip");

    procedure vr_recfl (handle : C.short; rect : access C.short);
    pragma Import (C, vr_recfl, "vr_recfl");

    procedure vsf_interior (handle, style : C.short);
    pragma Import (C, vsf_interior, "vsf_interior");

    procedure vsf_color (handle, color : C.short);
    pragma Import (C, vsf_color, "vsf_color");

    procedure vsl_color (handle, color : C.short);
    pragma Import (C, vsl_color, "vsl_color");

    -- Event
    type Message_Array is array (0 .. 7) of C.short;

    function mt_evnt_multi(Typ, Clicks, Which_Button, Which_State : C.short;
                           Enter_Exit1, In_1X, In_1y, In_1w, In_1h : C.short;
                           Enter_exit2, In_2X, In_2y, In_2w, In_2h : C.short;
                           Mesag_Buf : access Message_Array;
                           Interval : C.unsigned_long;
                           Out_X, Out_Y, Button_State, Key_State, Key, Return_Count : access C.short;
                           global_aes : System.Address) return C.short;
    pragma Import(C, mt_evnt_multi, "mt_evnt_multi");

    function evnt_multi(Typ, Clicks, Which_Button, Which_State,
                        Enter_Exit1, In_1x, In_1y, In_1w, In_1h : C.short;
                        Enter_Exit2, In_2x, In_2y, In_2w, In_2h : C.short;
                        Mesag_Buf : access Message_Array;
                        Interval : C.unsigned_long;
                        Out_X, Out_Y, Button_State, Key_State, Key, Return_Count : access C.short) return C.short is
    begin
        return mt_evnt_multi(Typ, Clicks, Which_Button, Which_State,
                             Enter_Exit1, In_1x, In_1y, In_1w, In_1h,
                             Enter_Exit2, In_2x, In_2y, In_2w, In_2h,
                             Mesag_Buf, Interval, Out_X, Out_Y,
                             Button_State, Key_State, Key, Return_Count, aes_global);
    end evnt_multi;



    -- Constants
    WM_REDRAW  : constant := 20;
    WM_CLOSED  : constant := 21;
    NAME       : constant := 1;
    CLOSER     : constant := 2;
    MOVER      : constant := 4;
    FULLER     : constant := 8;

    FIS_SOLID  : constant := 1;

    MU_KEYBD            : constant C.short := 16#0001#;
    MU_BUTTON           : constant C.short := 16#0002#;
    MU_M1               : constant C.short := 16#0004#;
    MU_M2               : constant C.short := 16#0008#;
    MU_MESAG            : constant C.short := 16#0010#;
    MU_TIMER            : constant C.short := 16#0020#;
    MU_WHEEL            : constant C.short := 16#0040#;
    MU_MX               : constant C.short := 16#0080#;
    MU_NORM_KEYBD       : constant C.short := 16#0100#;
    MU_DYNAMIC_KEYBD    : constant C.short := 16#0200#;
    X_MU_DIALOG         : constant C.short := 16#0400#;



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
Put_Line("0.0");
    app_id := appl_init;
Put_Line("0");
    declare
        Work_In  : Work_Array := (10 => 2, others => 1);
        Work_Out : Int57_Array;
        Dummy    : aliased C.short := 0;
    begin
        Vdi_Handle := graf_handle (Dummy'Access, Dummy'Access, Dummy'Access, Dummy'Access);

        Put_Line("1");

        v_opnvwk (Work_In, Vdi_Handle'Access, Work_Out);

Put_Line("2");
    end;

    Win := wind_create(NAME + CLOSER + MOVER + FULLER, 50, 50, 320, 200);
Put_Line("3");
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
